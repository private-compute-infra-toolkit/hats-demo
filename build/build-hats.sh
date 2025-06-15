#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Allow opts user to write to these folders without root.
set -e

chmod -R o+rwx /workspace
chmod -R o+rwx /home/optsuser

cd /workspace/client/scripts/
PREBUILT_DIR=/workspace/client/prebuilt

source ./build-lib.sh

build_hats_launcher "$PREBUILT_DIR"
build_tvs "$PREBUILT_DIR"

TAR_DIR="$PREBUILT_DIR/tar"
mkdir -p "$TAR_DIR"
build_oak_containers_stage0 "$TAR_DIR"
build_oak_containers_stage1 "$TAR_DIR"
build_oak_containers_kernel "$TAR_DIR"
# syslogd file is required in prebuilt folder for hats_system_image to build.
build_oak_containers_syslogd "$PREBUILT_DIR"

# Building hats_system_image requires non-root access.
# And optsuser cannot modify root bazel-bin folder, we get around by poinintg to the specific directory.
# We lose access to cache in this case but the compilation time is only increased by around 1min.
runuser -u optsuser -- bazel --output_base=/home/optsuser/ build -c opt //client/system_image:hats_system_image_test_single --//:syslogd_source=binary
cp /home/optsuser/execroot/_main/bazel-out/k8-opt/bin/client/system_image/hats_system_image_test_single.tar "$TAR_DIR/hats_system_image.tar"
xz --force "$TAR_DIR/hats_system_image.tar"

mv -f "$TAR_DIR/stage1.cpio" "$TAR_DIR/initrd.cpio.xz"
mv -f "$TAR_DIR/bzImage" "$TAR_DIR/kernel_bin"
mv -f "$TAR_DIR/hats_system_image.tar.xz" "$TAR_DIR/system.tar.xz"
tar --mode a=rx,u+w --sort=name --owner=root:0 --group=root:0 --mtime='@0' -C "$TAR_DIR" -cf "$PREBUILT_DIR/system_bundle.tar" .

# Remove unimportant files.
rm -rf "$TAR_DIR"
rm "$PREBUILT_DIR/BUILD"
rm "$PREBUILT_DIR/oak_containers_syslogd"
