#!/bin/bash
# Copyright 2024 Google LLC
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

cp ./bfe-test.json ./bidding-auction-servers/bfe-test.json
pushd ./bidding-auction-servers/
# Setup arguments.
INPUT_PATH=./bfe-test.json
BFE_HOST_ADDRESS=192.168.84.102:50051
CLIENT_IP=192.168.84.100
LIVE_KEY_ENDPOINT="http://localhost:9999"

# Setup keys.
LIVE_KEYS=$(curl ${LIVE_KEY_ENDPOINT})
PUBLIC_KEY=$(echo $LIVE_KEYS | jq -r .keys[0].key)
KEY_ID=$(echo $LIVE_KEYS | jq -r .keys[0].id)

echo $LIVE_KEYS
echo $KEY_ID
echo $PUBLIC_KEY
# Run the tool with desired arguments.
sudo DOCKER_NETWORK=ba-dev ./builders/tools/bazel-debian run //tools/secure_invoke:invoke \
    -- \
    -target_service=bfe \
    -input_file="/src/workspace/${INPUT_PATH}" \
    -host_addr=${BFE_HOST_ADDRESS} \
    -client_ip=${CLIENT_IP} \
    -public_key=${PUBLIC_KEY} \
    -key_id=${KEY_ID} \
    -insecure
popd > /dev/null
