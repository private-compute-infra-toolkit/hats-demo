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

docker run --network gemma3_hats-compose \
hats-devtools:latest \
curl http://server1:11434/api/chat -d '{
  "model": "gemma3:1b",
  "messages": [
    { "role": "user", "content": "Reply only your name in the response." }
  ]
}'

exit_code=$?
if [ $exit_code -eq 0 ]; then
  echo "Test passed."
else
  echo "Test failed."
fi
exit $exit_code
