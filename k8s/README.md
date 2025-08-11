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

**Note:** To run this demo, you may need to temporarily disable SELinux.

To check the status of SELinux, run:
```bash
getenforce
```

If it is `Enforcing`, you can temporarily disable it with:
```bash
sudo setenforce 0
```


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

## Troubleshooting

If you see an error in the `kubectl logs` output that looks like:
```
tvs-1      | W0811 19:27:24.314754      26 tvs-service.cc:92] Invalid or malformed command. UNKNOWN: Failed to verify report. No matching appraisal policy found
server1-1  | I0811 19:27:25.744291      50 logs-service.cc:55] oak-orchestrator.service: Error: couldn't fetch single tvs client: "error from tvs server: Error status: Unknown, message: \"Failed to read from stream. Invalid or malformed command. UNKNOWN: Failed to verify report. No matching appraisal policy found\", details: [], metadata: MetadataMap { headers: {} }"
```
This means that the hardware attestation couldn't be verified by the attestation verification service. Please copy the policies produced by TVS (after the line `Maybe try the following appraisal policy:`) and paste it into `appraisal-policy.prototext` if you are on a SNP-enabled machine, or `insecure-appraisal-policy.prototext` otherwise. An example of the policy looks like:
```
tvs-1      | [2025-08-11T19:27:24Z DEBUG policy_manager::debug] Maybe try the following appraisal policy:
                    policies {
                      measurement {
                        stage0_measurement {

                      amd_sev {
                        sha384: "2ca92db10d674548cca183c1ef896ce240f786e17903f2fb2eb6e63d1d130ed440dbd31b2254d93572033614e673639e"
                        min_tcb_version {
                          boot_loader: 4
                          snp: 23
                          microcode: 213
                        }
                      }
                        kernel_image_sha256: "f9d0584247b46cc234a862aa8cd08765b38405022253a78b9af189c4cedbe447"
                        kernel_setup_data_sha256: "75f091da89ce81e9decb378c3b72a948aed5892612256b3a6e8305ed034ec39a"
                        init_ram_fs_sha256: "b2b5eda097c2e15988fd3837145432e3792124dbe0586edd961efda497274391"
                        memory_map_sha256: "ee25374b63f420432cf01ef0220df36d37a2288c52f4683c0fe5eaf6dd6dcc29"
                        acpi_table_sha256: "cc6218b513944e1973e113f2be6a74fd21b5272a323cf7c693e06d18e9a677a5"
                        kernel_cmd_line_regex: "^ console=ttyS0 panic=-1 brd.rd_nr=1 brd.rd_size=25165824 brd.max_part=1 ip=10.3.3.2::10.3.3.1:255.255.255.0::enp0s1:off quiet -- --launcher-addr=vsock://2:.*$"
                        system_image_sha256: "af99ae9fdee76f949a3cb08fd0302e47542c02690299a970f33a41abe8caea09"
                        container_binary_sha256: "bfb9719fd8ebdc529c8a013f9e697fd11aeb0acc53633bf83353a3f4a04c44b6"
                      }
                    }
```
If you encounter issues, check the logs of the pods in the `hats-demo-cluster` for more information.

```bash
kubectl --context kind-hats-demo-cluster logs -f <pod-name>
```
You can also check the Kind cluster logs for any issues related to the cluster setup.

```bash
kind get logs --name hats-demo-cluster
```
If you need to start over, you can delete the cluster and recreate it.

```bash
kind delete cluster --name hats-demo-cluster
./run.sh
```
