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
  rm -rf $DEMO_DIR
  mkdir -p $DEMO_DIR
  cp -r $SKELETON_DIR/. $DEMO_DIR

  pushd $REPO_ROOT # 1
  git submodule update --init --recursive
  pushd $REPO_ROOT/components/hats/
  # Pin to specific hash to prevent demo going out of shape.
  git checkout 50f063865113f1ccaa835ad4eb306542632586a5
  popd
  popd # 1
}

build_hats_stack () {
  pushd $REPO_ROOT/components/hats/client/scripts/
  local SCRIPTS_DIR="$(dirname "$0")"
  readonly SCRIPTS_DIR
  local PREBUILT_DIR="$(readlink -f "$SCRIPTS_DIR/../prebuilt")"
  readonly PREBUILT_DIR
  cd "$SCRIPTS_DIR"
  mkdir -p "$PREBUILT_DIR"

  # shellcheck disable=1091
  source ./build-lib.sh

  build_hats_launcher "$PREBUILT_DIR"
  build_tvs "$PREBUILT_DIR"
  build_test_keygen "$PREBUILT_DIR"
  build_test_application_container_bundle_tar "$PREBUILT_DIR"

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

  mv -f "$PREBUILT_DIR/bundle.tar" "$DEMO_DIR/ta_hats_stack/runtime_bundle.tar"
  mv -f "$PREBUILT_DIR/system_bundle.tar" "$DEMO_DIR/ta_hats_stack/"
  mv -f "$PREBUILT_DIR/launcher_main" "$DEMO_DIR/ta_hats_stack/"
  mv -f "$PREBUILT_DIR/tvs-server_main" "$DEMO_DIR/tvs/"
  mv -f "$PREBUILT_DIR/key-gen" "$DEMO_DIR/"
}

build_trusted_app_client () {
  pushd $REPO_ROOT/components/hats/client/scripts/
  local SCRIPTS_DIR="$(dirname "$0")"
  readonly SCRIPTS_DIR
  local PREBUILT_DIR="$(readlink -f "$SCRIPTS_DIR/../prebuilt")"
  readonly PREBUILT_DIR
  cd "$SCRIPTS_DIR"
  mkdir -p "$PREBUILT_DIR"

  # shellcheck disable=1091
  source ./build-lib.sh

  build_trusted_application_client "$PREBUILT_DIR"
  popd

  mv -f "$PREBUILT_DIR/trusted_application_client_main" "$DEMO_DIR/"
}

package() {
  pushd $(dirname $BUILD_LOC)
  tar --sort=name --owner=root:0 --group=root:0 --mtime='UTC 1980-02-01' -cf demo.tar demo
  echo "$(cat demo.tar.sha256) demo.tar" | sha256sum --check
  popd
}

prepare_demo
build_hats_stack
build_trusted_app_client
package
