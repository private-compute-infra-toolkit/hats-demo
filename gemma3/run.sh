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

if ! lsmod | grep -q vhost_vsock;
then
  read -p "The vhost_vsock kernel module is not loaded, but it is required by this script. Would you like to load it now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo modprobe vhost_vsock
  else
    printf "\033[0;31m!!!!! The demo requires the vhost_vsock kernel module. Please load it manually and run this script again.\033[0m\n"
    exit 1
  fi
fi

output=$(docker run --privileged hats-devtools:latest sevctl ok snp 2>&1)
if echo "$output" | grep -q "One or more tests in sevctl-ok reported a failure"; then
  echo "Your device is not an AMD SEV-SNP supported device."
  echo "Therefore, we can only run in insecure mode (no stage0 verification)."
  read -p "Would you like to proceed? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    DOCKER_COMPOSE_FILE="insecure-docker-compose.yaml"
  else
    echo "Aborting."
    exit 1
  fi
else
  DOCKER_COMPOSE_FILE="docker-compose.yaml"
fi

cleanup() {
    echo "Stopping docker compose..."
    docker compose -f "$DOCKER_COMPOSE_FILE" down --remove-orphans
}
trap cleanup EXIT

docker compose -f "$DOCKER_COMPOSE_FILE" up -d --remove-orphans

# Start streaming logs in the background
docker compose -f "$DOCKER_COMPOSE_FILE" logs -f &

ok=0
echo "Waiting for application to start..."
for i in {1..36}; do
  # Check logs without consuming them
  if docker compose -f "$DOCKER_COMPOSE_FILE" logs | grep -q "/api/generate"; then
    echo "Application started successfully."
    ok=1
    break
  fi
  sleep 5
done

if [ $ok -eq 1 ]; then
  ./test.sh;
fi

echo "Waiting for termination signal"
tail -f /dev/null
