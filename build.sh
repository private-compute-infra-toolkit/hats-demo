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

echo '>>>>>>> Creating Output / Cache folders '
mkdir -p .cache/nix/var/nix
mkdir -p .cache/bazel
mkdir -p ./build/output

echo '>>>>>>> Pull Hats Repo'
git submodule update --init --recursive

echo '>>>>>>> Temporarily apply hats patch'
pushd ./hats
git apply ../src/hats.patch
popd

echo '>>>>>>> Build Hats Demo stack'
# Setup the build environment...
docker build -t pcit_hats_kokoro_builder:latest ./hats/google_internal/kokoro/
# Setup the non-root user to run with this docker container.
# We'd like UID to match external one in order for the docker container to
# access host filesystems.
user_id=$(id -u)
group_id=$(id -g)
docker build -t pcit_hats_kokoro_builder_demo:latest - <<EOF
FROM pcit_hats_kokoro_builder:latest
RUN git config --global --add safe.directory '*'
RUN groupadd builder -g ${group_id}
RUN useradd -m builder -u ${user_id} -g ${group_id}
RUN chown -R builder:builder /nix/
USER builder
EOF

command='
./client/trusted_application/build-for-test.sh && \
bazel build -c opt //client/launcher:launcher_main && \
cp bazel-bin/client/launcher/launcher_main client/trusted_application/test_data/ && \
bazel build -c opt //tvs/standalone_server:tvs-server_main && \
cp bazel-bin/tvs/standalone_server/tvs-server_main client/trusted_application/test_data/ && \
bazel build -c opt //client/trusted_application/client:trusted_application_client_main && \
cp bazel-bin/client/trusted_application/client/trusted_application_client_main client/trusted_application/test_data/ && \
chmod -R +rw /workspace/hats/client/trusted_application/test_data
'
# The docker run command will execute the build process with builder user and
# matching the UID:GID of the host so that no host permission change is
# required.
# We add caching folders to reduce cross run build latency. Otherwise, it can
# take 1 hour to build.
docker run \
  -u ${user_id}:${group_id} \
  -v $(pwd):/workspace \
  -v $(pwd)/build/output/:/workspace/hats/client/trusted_application/test_data \
  -v $(pwd)/.cache/nix:/nix \
  -v $(pwd)/.cache/bazel:/home/builder/ \
  -w /workspace/hats \
  pcit_hats_kokoro_builder_demo:latest \
  bash -c "${command}"

docker build -t tvs:latest -f build/Dockerfile.tvs build
docker build -t launcher:latest -f build/Dockerfile.launcher build
docker build -t hats-devtools:latest -f build/Dockerfile.devtools build
