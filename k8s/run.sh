#!/bin/bash

CLUSTER_NAME="hats-demo-cluster"

# Cleanup function to be called on exit
cleanup() {
    echo "Cleaning up and deleting Kind cluster: $CLUSTER_NAME..."
    kind delete cluster --name "$CLUSTER_NAME"
}

# Trap the EXIT signal to call the cleanup function
trap cleanup EXIT

# Function to check for AMD SEV-SNP support
check_snp_support() {
    if lsmod | grep -q sev; then
        return 0 # SEV module is loaded
    fi

    if [ -e /dev/sev ]; then
        return 0 # SEV device exists
    fi

    # Check CPU info for the sev feature
    if grep -q -o sev /proc/cpuinfo; then
        return 0
    fi

    return 1
}

# Create kind cluster
echo "Creating Kind cluster: $CLUSTER_NAME..."
kind create cluster --name "$CLUSTER_NAME" --config kind.yaml

# Load docker images
echo "Loading Docker images into the Kind cluster..."
kind load docker-image tvs:latest --name "$CLUSTER_NAME"
kind load docker-image launcher:latest --name "$CLUSTER_NAME"
kind load docker-image hats-devtools:latest --name "$CLUSTER_NAME"

# Check for SNP support and deploy the appropriate manifest
if check_snp_support; then
    echo "AMD SEV-SNP support detected. Deploying in secure mode."
    kubectl apply --context "kind-$CLUSTER_NAME" -f manifest.yaml
else
    echo "AMD SEV-SNP support not detected."
    read -p "Do you want to continue in insecure mode? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deploying in insecure mode."
        kubectl apply --context "kind-$CLUSTER_NAME" -f insecure-manifest.yaml
    else
        echo "Aborting."
        exit 1
    fi
fi

echo "Deployment complete. The cluster will be destroyed when this script is terminated."
# Keep the script running to keep the cluster alive.
# The user can terminate it with Ctrl+C.
while true; do
    sleep 1
done