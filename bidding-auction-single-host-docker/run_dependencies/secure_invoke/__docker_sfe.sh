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

INPUT_PATH=./sfe-test.json
SFE_HOST_ADDRESS=192.168.84.104:50053
CLIENT_IP=192.168.84.100
LIVE_KEY_ENDPOINT="192.168.84.200:9999"

LIVE_KEYS=$(curl ${LIVE_KEY_ENDPOINT})
PUBLIC_KEY=$(echo $LIVE_KEYS | jq -r .keys[0].key)
KEY_ID=$(echo $LIVE_KEYS | jq -r .keys[0].id)

echo $LIVE_KEYS
echo $KEY_ID
echo $PUBLIC_KEY
./invoke invoke \
    -target_service=sfe \
    -input_file="${INPUT_PATH}" \
    -host_addr=${SFE_HOST_ADDRESS} \
    -client_ip=${CLIENT_IP} \
    -public_key=${PUBLIC_KEY} \
    -key_id=${KEY_ID} \
    --op=invoke \
    -insecure
