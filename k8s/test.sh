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

CLUSTER_NAME="hats-demo-cluster"
KUBE_CONTEXT="kind-$CLUSTER_NAME"

# Apply the test client manifest
kubectl apply --context "$KUBE_CONTEXT" -f test-client.yaml

# Wait for the pod to complete. We'll poll its status.
echo "Waiting for test client to complete..."
for i in {1..30}; do
  STATUS=$(kubectl get pod --context "$KUBE_CONTEXT" test-client -o jsonpath='{.status.phase}')
  if [ "$STATUS" == "Succeeded" ] || [ "$STATUS" == "Failed" ]; then
    break
  fi
  sleep 2
done

# Get the logs
echo "Test client finished. Getting logs:"
kubectl logs --context "$KUBE_CONTEXT" test-client

# Check the container's exit code to determine pass/fail
EXIT_CODE=$(kubectl get pod --context "$KUBE_CONTEXT" test-client -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}')

# Clean up the pod
echo "Cleaning up the test client pod..."
kubectl delete pod --context "$KUBE_CONTEXT" test-client --ignore-not-found=true > /dev/null

# Final result
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Test passed."
  exit 0
else
  echo "Test failed."
  exit 1
fi
