# Kubernetes Kind Demo with Trusted Application

This demo showcases how to run a trusted application using Kubernetes with Kind (Kubernetes in Docker).

## Prerequisites

- Docker
- Kind
- kubectl

Please follow the official documentation to install the tools:
- **Kind:** https://kind.sigs.k8s.io/docs/user/quick-start/#installation
- **kubectl:** https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

This demo only supports Linux.

## Build demo artifacts

From the git repo root, run `./build.sh`. This will build the necessary Docker images.

## Update Stage0 Measurement for SNP machine only

In `appraisal-policy.prototext` for secure mode, the stage0 measurement varies for different CPU types. To compute the stage0 measurement, please first run the following from the git repo root:

```bash
docker run --privileged -v $(pwd)/build/output/system_bundle_test_single.tar:/system_bundle.tar hats-devtools:latest /generate_stage_measurement.sh --vcpus 1
```
Then, update the `stage0_measurement` field in `k8s/appraisal-policy.prototext` with the generated value.

## Running the Demo

To run the demo, execute the `run.sh` script from within the `k8s` directory:

```bash
./run.sh
```

The script will first check if your machine supports AMD SEV-SNP.

- **Secure Mode:** If your machine has AMD SEV-SNP support, the script will create a Kind cluster and deploy the application using `manifest.yaml`. This configuration ensures that the application runs in a trusted environment with hardware-enforced security.

- **Insecure Mode:** If your machine does not support AMD SEV-SNP, the script will notify you and ask if you want to continue in insecure mode. If you agree, it will deploy the application using `insecure-manifest.yaml`. In this mode, the application will run without the hardware-level security guarantees, and stage0 verification will be skipped.

The script will also load the required Docker images into the Kind cluster.

## Testing the Application

After the application is running, you can test it by running the `test.sh` script in a separate terminal from within the `k8s` directory:

```bash
./test.sh
```

If the application is running correctly, you should see the following output:

```
Hello from inside the trusted application!
```

## Interacting with the Cluster

The `run.sh` script creates a cluster named `hats-demo-cluster`. To interact with it, you must specify the cluster context for `kubectl` commands.

For example, to view the logs of the running pod:

```bash
# By label
kubectl --context kind-hats-demo-cluster logs -f -l app=server1

# Or by specific pod name
kubectl --context kind-hats-demo-cluster logs -f <pod-name>
```

To delete the cluster after you are done (if you terminated `run.sh` prematurely):

```bash
kind delete cluster --name hats-demo-cluster
```

## Files

- `manifest.yaml`: Kubernetes manifest for secure mode (requires AMD SEV-SNP).
- `insecure-manifest.yaml`: Kubernetes manifest for insecure mode (does not require AMD SEV-SNP).
- `run.sh`: A script to check for AMD SEV-SNP support and deploy the appropriate Kubernetes manifest.
- `test.sh`: A script to test the application.
- `appraisal-policy.prototext`: Security policy for the trusted application in secure mode.
- `insecure-appraisal-policy.prototext`: Security policy for the trusted application in insecure mode.
- `kind.yaml`: Kind cluster configuration file.
- `README.md`: This file.