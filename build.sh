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

mkdir -p ./.hats-stack
# cache files shouldn't be inside the build folder to speed up docker context.
mkdir -p ./.hats-cache
mkdir -p ./run/
OUTPUT="$(readlink -f ./.hats-stack)"
HATS_CACHE="$(readlink -f ./.hats-cache)"
WORKSPACE="$(readlink -f ./src/hats/)"
RUNTIME="$(readlink -f ./run/)"
echo OUTPUT folder: $OUTPUT
echo HATS_CACHE folder: $HATS_CACHE
echo WORKSPACE: $WORKSPACE

HATS_COMMIT=33b91fe60d55a1d65b044efd4962e030d18fd7cb

echo '===== Pull Hats ===='
pushd src
git clone sso://privacysandbox/hats
pushd hats
git checkout $HATS_COMMIT
git submodule update --init --recursive
git reset --hard
git clean -f -d
git apply ../hats.patch
popd # Hats
popd # src

echo '======== Build Hats Builder =========='
pushd ./build/
docker build --tag hats-demo-builder:latest .
popd

echo '=========== Build Hats ==========='
docker run \
  -v $WORKSPACE:/workspace \
  -v $OUTPUT:/workspace/client/prebuilt \
  -v $HATS_CACHE/nix:/nix \
  -v $HATS_CACHE/bazel:/root/.cache/ \
  -v $HATS_CACHE/optsuser:/home/optsuser/ \
  -v $HATS_CACHE/optsuser-bazel:/home/optsuser/.cache \
  hats-demo-builder:latest \
  bash -c /build-hats.sh

echo '============ Packaging Launcher and TVS =========='
cp -f $OUTPUT/launcher_main ./build/launcher/
pushd ./build/launcher/
docker build --tag launcher:latest .
popd

cp -f $OUTPUT/tvs-server_main ./build/tvs/
pushd ./build/tvs/
docker build --tag tvs:latest .
popd

cp -f $OUTPUT/system_bundle.tar $RUNTIME/
mkdir -p run
pushd run
docker save launcher:latest -o launcher-image.tar
docker save tvs:latest -o tvs-image.tar
popd
