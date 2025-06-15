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

update_container_binary_sha256() {
  echo "Updating for: $1"
  sha=$(sha256sum $1 | cut -d ' ' -f 1)
  filename=$(basename $1)
  echo "s/container_binary_sha256: \".*\" # $filename/container_binary_sha256: \"$sha\" # $filename/g" "$(dirname $(dirname $1))/conf/appraisal_policy.prototext"
  sed -i "s/container_binary_sha256: \".*\" # $filename/container_binary_sha256: \"$sha\" # $filename/g" "$(dirname $(dirname $1))/conf/appraisal_policy.prototext"
}

export -f update_container_binary_sha256
OUTPUT="$(readlink -f $(dirname $0)/../output)"
find -L $OUTPUT -name workload.tar | xargs -I{} bash -c 'update_container_binary_sha256 "$@"' _ {}
