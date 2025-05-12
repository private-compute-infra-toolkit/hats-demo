#!/bin/bash

### Build the base system image with Docker.
### This script is expected to be run manually, and infrequently, for now.
### It only needs to be run if base_image.Dockerfile changes.

set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPTS_DIR="$(dirname "$0")"

cd "$SCRIPTS_DIR"

mkdir --parent target

function build_base {
  local tag=$1
  local dockerfile=$2
  local tar_name=$3

  docker buildx build . \
   --tag="$tag":latest \
   --file "$dockerfile"

  # We need to actually create a container, otherwise we won't be able to use
  # `docker export` that gives us a filesystem image.
  # (`docker save` creates a tarball which has all the layers separate, which is
  # _not_ what we want.)
  local NEW_DOCKER_CONTAINER_ID="$(docker create "$tag":latest)"

  # We export a plain tarball.
  # The oak_containers_sysimage_base oci_image rule will use this tarball to
  # create an OCI image that it can then push to Google artifact registry.
  # There *might* be a better approach here, but this is working for now.
  docker export "$NEW_DOCKER_CONTAINER_ID" > target/"$tar_name"
  docker rm "$NEW_DOCKER_CONTAINER_ID"

  # Repackage the base image tar so that entries are in a consistent order and have a
  # consistent mtime. fakeroot ensures that file permissions are maintained, even
  # when not building as root.
  #
  sandbox="$(mktemp -d)"
  fakeroot -- sh -c "\
    mkdir \"${sandbox}\"/rootfs \
    && tar --extract --file target/$tar_name --directory \"${sandbox}\"/rootfs \
    && cp config.json \"${sandbox}\"/ \
    && touch \"${sandbox}\"/rootfs/root/.ollama/history \
    && tar --create --sort=name --file target/$tar_name --mtime='2000-01-01Z' \
      --numeric-owner --directory \"${sandbox}\" ."
  rm -rf -- "$sandbox"
}

function build_ollama_gemma_image {
  build_base "ollama-gemma3-base" "ollama-image.Dockerfile" "ollama-gemma3-image.tar"
}

build_ollama_gemma_image
