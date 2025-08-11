# Gemma3 Demo with Trusted Application

This demo showcases how to run a trusted application using docker compose. The trusted application in this demo is an Ollama server running the Gemma3 language model.

## Prerequisites

- Docker
- Docker Compose
- An AMD SEV-SNP enabled machine (for secure mode)

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

From the git repo root, run `./build.sh`.

## Update Stage0 Measurement for SNP machine only

In `appraisal-policy.prototext` for secure mode, the stage0 measurement varies for
different CPU types. To compute the stage0 measurement, please first run:

From git repo root:
```bash
docker run --privileged -v $(pwd)/build/output/system_bundle_test_single.tar:/system_bundle.tar hats-devtools:latest /generate_stage0_measurement.sh --vcpus 1
```

## Running the Demo

To run the demo, execute the `run.sh` script:

```bash
./run.sh
```

The script will first check if your machine supports AMD SEV-SNP.

- **Secure Mode:** If your machine has AMD SEV-SNP support, the script will launch the application using `docker-compose.yaml`. This configuration ensures that the application runs in a trusted environment with hardware-enforced security.

- **Insecure Mode:** If your machine does not support AMD SEV-SNP, the script will notify you and ask if you want to continue in insecure mode. If you agree, it will launch the application using `insecure-docker-compose.yaml`. In this mode, the application will run without the hardware-level security guarantees, and stage0 verification will be skipped.

## Testing the Application

After the application is running, you can test it by running the `test.sh` script in a separate terminal:

```bash
./test.sh
```

This script sends a request to the Ollama server asking for its name. If the application is running correctly, you should see a response from the Gemma3 model.

## Files

- `docker-compose.yaml`: Docker compose configuration for secure mode (requires AMD SEV-SNP).
- `insecure-docker-compose.yaml`: Docker compose configuration for insecure mode (does not require AMD SEV-SNP).
- `run.sh`: A script to check for AMD SEV-SNP support and launch the appropriate docker compose configuration.
- `appraisal-policy.prototext`: Security policy for the trusted application in secure mode.
- `insecure-appraisal-policy.prototext`: Security policy for the trusted application in insecure mode.
- `test.sh`: A script to test the application.

## Troubleshooting

If you see an error that looks like:

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