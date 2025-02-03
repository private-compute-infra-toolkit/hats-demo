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

# Launch script that also checks for whether TVS server is up and running.
TVS_ADDRESS='localhost:7774'

if [[ ! -f "$1" ]]; then
  echo "Please provide a valid path containing launcher config."
  exit 1
fi

if [[ ! `curl -sS localhost:7774 2>&1 | grep "(1) Received HTTP/0.9 when not allowed"` ]]; then
  echo "TVS server at address $TVS_ADDRESS is not responding, please run the server again."
  exit 1
fi

sudo ./launcher_main \
  --curl_opt_cainfo=`curl-config --ca` \
  --tvs_addresses=localhost:7774 \
  --use_tls=false \
  --launcher_config_path=$1 \
  --tvs_authentication_key="$(cat ./launcher_hold_user_authentication_private_key_hex)" \
  --qemu_log_to_std \
  --minloglevel=0 \
  --stderrthreshold=0
