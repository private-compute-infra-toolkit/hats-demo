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

# Use a base image with bash installed
FROM python:alpine3.12

COPY public_hold_public_hpke_key_hex /public_key
COPY launch-local-public-key-server.py /launch-local-public-key-server.py
RUN pip install quart hypercorn

ENTRYPOINT ["python", "/launch-local-public-key-server.py"]
