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

build_ba() {
echo "$1"
echo '============ Build B&A Stack A ============'
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

cp -f dist/debian/hats/auction_service/runc_runtime_bundle.tar "$1/stack_a_auction.tar"
cp -f dist/debian/hats/bidding_service/runc_runtime_bundle.tar "$1/stack_a_bidding.tar"
cp -f dist/debian/hats/buyer_frontend_service/runc_runtime_bundle.tar "$1/stack_a_bfe.tar"
cp -f dist/debian/hats/seller_frontend_service/runc_runtime_bundle.tar "$1/stack_a_sfe.tar"

echo '============ Build B&A Stack B ============'
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
cp -f dist/debian/hats/auction_service/runc_runtime_bundle.tar "$1/stack_b_auction.tar"
cp -f dist/debian/hats/bidding_service/runc_runtime_bundle.tar "$1/stack_b_bidding.tar"
cp -f dist/debian/hats/buyer_frontend_service/runc_runtime_bundle.tar "$1/stack_b_bfe.tar"
cp -f dist/debian/hats/seller_frontend_service/runc_runtime_bundle.tar "$1/stack_b_sfe.tar"
}

pushd build_dependencies
mkdir -p output
OUTPUT="$(readlink -f ./output)"
HATS_CACHE="$(readlink -f ./.hats-cache)"
# Generate test server SSL cert.
pushd $OUTPUT
openssl ecparam -name prime256v1 -genkey -out localhost-key.pem
openssl req -x509 -new -key localhost-key.pem -out localhost.pem -sha256 -days 3650 -nodes -subj "/C=XX/ST=CA/L=Cupertino/O=localhost/OU=adtech/CN=localhost" -addext "subjectAltName = DNS:localhost"
popd

pushd bidding-auction-server
build_ba $OUTPUT
echo '====== Build Secure Invoke Tool ====='
./builders/tools/bazel-debian build //tools/secure_invoke:invoke @cddl_lib//:cddl
cp -f bazel-bin/tools/secure_invoke/invoke $OUTPUT/invoke
cp -f bazel-bin/external/cddl_lib/libcddl.so $OUTPUT/libcddl.so
popd

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

popd
