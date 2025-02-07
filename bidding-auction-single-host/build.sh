#!/bin/bash
# Copyright 2025 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

BUILD_LOC="$(readlink -f $0)"
REPO_ROOT="$(dirname $(dirname $BUILD_LOC))"
DEMO_DIR="$(dirname $BUILD_LOC)/demo"
SKELETON_DIR="$(dirname $BUILD_LOC)/skeleton"

prepare_demo() {
  mkdir -p $DEMO_DIR
  cp -r $SKELETON_DIR/. $DEMO_DIR

  pushd $REPO_ROOT # 1
  git submodule update --init --recursive
  pushd $REPO_ROOT/components/hats/
  # Pin to specific hash to prevent demo going out of shape.
  git checkout 8abb7e99106e4cc1af1cc5433657fd98e617bf8f
  popd
  pushd $REPO_ROOT/components/bidding-auction-server/
  # Pin to the pending CL for now. This is blocked by ACL changes.
  git fetch sso://team/android-privacy-sandbox-remarketing/fledge/servers/bidding-auction-server refs/changes/58/2413458/11 && git checkout FETCH_HEAD
  git submodule update --init --recursive
  popd
  popd # 1
}

build_hats_stack () {
  pushd $REPO_ROOT/components/hats/client/scripts/
  SCRIPTS_DIR="$(dirname "$0")"
  readonly SCRIPTS_DIR
  PREBUILT_DIR="$(readlink -f "$SCRIPTS_DIR/../prebuilt")"
  readonly PREBUILT_DIR
  cd "$SCRIPTS_DIR"
  mkdir -p "$PREBUILT_DIR"

  # shellcheck disable=1091
  source ./build-lib.sh

  build_hats_launcher "$PREBUILT_DIR"
  build_tvs "$PREBUILT_DIR"
  build_test_keygen "$PREBUILT_DIR"

  TAR_DIR="$PREBUILT_DIR/tar"
  mkdir -p "$TAR_DIR"
  build_oak_containers_stage0 "$PREBUILT_DIR"
  build_oak_containers_stage1 "$PREBUILT_DIR"
  build_oak_containers_kernel "$PREBUILT_DIR"
  build_oak_containers_syslogd "$PREBUILT_DIR"
  build_hats_containers_images "$PREBUILT_DIR"
  popd

  mv -f "$PREBUILT_DIR/stage0_bin" "$TAR_DIR/stage0_bin"
  mv -f "$PREBUILT_DIR/stage1.cpio" "$TAR_DIR/initrd.cpio.xz"
  mv -f "$PREBUILT_DIR/bzImage" "$TAR_DIR/kernel_bin"
  mv -f "$PREBUILT_DIR/hats_system_image.tar.xz" "$TAR_DIR/system.tar.xz"
  tar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 1980-02-01' -C "$TAR_DIR" -cf "$PREBUILT_DIR/system_bundle.tar" .

  mv -f "$PREBUILT_DIR/system_bundle.tar" "$DEMO_DIR/ba_hats_stack/"
  mv -f "$PREBUILT_DIR/launcher_main" "$DEMO_DIR/ba_hats_stack/"
  mv -f "$PREBUILT_DIR/tvs-server_main" "$DEMO_DIR/tvs/"
  mv -f "$PREBUILT_DIR/key-gen" "$DEMO_DIR/"
}

build_ba_demo_stack () {
  pushd $REPO_ROOT/components/bidding-auction-server
  production/packaging/build_and_test_all_in_docker \
    --service-path bidding_service \
    --service-path auction_service \
    --service-path buyer_frontend_service \
    --service-path seller_frontend_service \
    --platform hats \
    --instance hats \
    --no-precommit \
    --no-tests \
    --build-flavor non_prod

  cp -r dist "$DEMO_DIR/ba_hats_stack/stack_a"

  production/packaging/build_and_test_all_in_docker \
    --service-path bidding_service \
    --service-path auction_service \
    --service-path buyer_frontend_service \
    --service-path seller_frontend_service \
    --platform hats \
    --instance hatsb \
    --no-precommit \
    --no-tests \
    --build-flavor non_prod

  cp -r dist "$DEMO_DIR/ba_hats_stack/stack_b"
  popd
}

package() {
  pushd $(dirname $BUILD_LOC)
  tar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 1980-02-01' -cf demo.tar demo
  sha256sum demo.tar
  popd
}

prepare_demo
build_hats_stack
build_ba_demo_stack
package
