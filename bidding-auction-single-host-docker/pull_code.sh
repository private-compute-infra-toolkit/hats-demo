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
BA_LOCAL_TESTING_APP_COMMIT=8fd45879db520dd4053645124fd81401e9c28ff5

pushd build_dependencies
echo '===== Pull B&A ===='
git clone sso://team/android-privacy-sandbox-remarketing/fledge/servers/bidding-auction-server
pushd bidding-auction-server
# TODO(sidachen): Remove once open sourced.
git fetch sso://team/android-privacy-sandbox-remarketing/fledge/servers/bidding-auction-server refs/changes/66/2434566/16 && git checkout FETCH_HEAD
git submodule update --init --recursive
popd # bidding-auction-server

echo '===== Pull Hats ===='
pushd hats-docker
git clone sso://privacysandbox/hats
pushd hats
git checkout $HATS_COMMIT
git submodule update --init --recursive
popd # hats
popd # hats-docker

popd # build_dependencies

pushd run_dependencies
echo '===== Pull B&A local testing app ====='
git clone https://github.com/privacysandbox/bidding-auction-local-testing-app.git
pushd bidding-auction-local-testing-app
git checkout $BA_LOCAL_TESTING_APP_COMMIT
popd
popd
