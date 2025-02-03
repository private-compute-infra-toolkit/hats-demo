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

SCRIPT_DIR="$(dirname $(readlink -f $0))"
docker build --network host -t public-key-server "$SCRIPT_DIR"
docker rm -f public-key-server-container
docker run -it --rm --ip 192.168.84.200 --network ba-dev --name public-key-server-container -p 9999:9999 -v "$SCRIPT_DIR"/public_hold_public_hpke_key_hex:/public_hold_public_hpke_key_hex public-key-server
