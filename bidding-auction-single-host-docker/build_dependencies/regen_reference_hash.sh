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

rm -rf .system_bundle
mkdir .system_bundle
tar -xf ./output/system_bundle.tar -C .system_bundle

# Exclude generated keys and system_bundle.tar, which only the internal matters.
rm reference_hash.txt
touch reference_hash.txt
find -L ./output/ -type f ! -name 'system_bundle.tar' ! -name '*.pem' | xargs sha256sum >> reference_hash.txt
find -L ./.system_bundle/ -type f | xargs sha256sum >> reference_hash.txt
cat reference_hash.txt
