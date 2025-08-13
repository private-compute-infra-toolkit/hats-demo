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
PATCH_FILE=../hats.patch
# Check if the patch can be cleanly reversed (meaning it's already applied)
if git apply --reverse --check "$PATCH_FILE" &>/dev/null; then
  echo "Patch '$PATCH_FILE' is already applied. Skipping."
else
  # If it can't be reversed, it needs to be applied
  echo "Applying patch '$PATCH_FILE'."
  git apply "$PATCH_FILE"
fi
popd

# the previous steps can fail but not the following.
set -e
function build_ollama_gemma_image {
  set -e
  echo '>>>>>>> Build Gemma3 demo'
  local tag='hats-demo-gemma3:latest'
  local tar_name='gemma3-image.tar'
  pushd build
  docker buildx build . \
   --tag="$tag" \
   --file "Dockerfile.gemma3"

  # We need to actually create a container, otherwise we won't be able to use
  # `docker export` that gives us a filesystem image.
  # (`docker save` creates a tarball which has all the layers separate, which is
  # _not_ what we want.)
  local NEW_DOCKER_CONTAINER_ID="$(docker create "$tag")"

  # We export a plain tarball.
  # The oak_containers_sysimage_base oci_image rule will use this tarball to
  # create an OCI image that it can then push to Google artifact registry.
  # There *might* be a better approach here, but this is working for now.
  docker export "$NEW_DOCKER_CONTAINER_ID" > output/"$tar_name"
  docker rm "$NEW_DOCKER_CONTAINER_ID"

  # Repackage the base image tar so that entries are in a consistent order and have a
  # consistent mtime. fakeroot ensures that file permissions are maintained, even
  # when not building as root.
  #
  # Check if the fakeroot command is available
  if ! command -v fakeroot &> /dev/null; then
    # If not found, print an error message to standard error and exit
    echo "Error: 'fakeroot' is not installed or not in your PATH." >&2
    echo "Please install it to continue (e.g., 'sudo apt-get install fakeroot' on Debian/Ubuntu)." >&2
    exit 1
  fi
  # The rest of your script continues here
  echo "fakeroot is installed. Proceeding..."

  sandbox="$(mktemp -d)"
  fakeroot -- sh -c "\
    mkdir \"${sandbox}\"/rootfs \
    && tar --extract --file output/$tar_name --directory \"${sandbox}\"/rootfs \
    && cp config-gemma3.json \"${sandbox}\"/config.json \
    && touch \"${sandbox}\"/rootfs/root/.ollama/history \
    && tar --create --sort=name --file output/$tar_name --mtime='2000-01-01Z' \
      --numeric-owner --directory \"${sandbox}\" ."
  rm -rf -- "$sandbox"
  popd
}

build_ollama_gemma_image

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
# allow group/user creation failure in case that they already exist.
RUN groupadd builder -g ${group_id} || true
RUN useradd -m builder -u ${user_id} -g ${group_id} || true
RUN chown -R ${user_id}:${group_id} /nix/
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

