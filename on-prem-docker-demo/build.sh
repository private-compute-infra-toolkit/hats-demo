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
HATS_COMMIT=eb85b5604221f9173152c109a4454afa457c386f

pushd build_dependencies

echo '===== Pull Hats ===='
pushd hats-docker
git clone sso://privacysandbox/hats
pushd hats
git checkout $HATS_COMMIT
git submodule update --init --recursive
popd # hats
popd # hats-docker

popd # build_dependencies


pushd build_dependencies
mkdir -p output
OUTPUT="$(readlink -f ./output)"
HATS_CACHE="$(readlink -f ./.hats-cache)"

pushd hats-docker
docker build --tag hats-demo-builder:latest .

# Build Hats with local cache folder.
# Caching the results to use across builds.
echo '=========== Build Hats ==========='
docker run \
  -v `pwd`/build-hats.sh:/build-hats.sh \
  -v `pwd`/hats:/workspace \
  -v $OUTPUT:/workspace/client/prebuilt \
  -v $HATS_CACHE/nix:/nix \
  -v $HATS_CACHE/bazel:/root/.cache/ \
  -v $HATS_CACHE/optsuser:/home/optsuser/ \
  -v $HATS_CACHE/optsuser-bazel:/home/optsuser/.cache \
  hats-demo-builder:latest \
  bash -c /build-hats.sh

popd # hats-docker

popd # build_dependencies
