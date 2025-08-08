# Docker Compose Demo with Trusted Application

This demo showcases how to run a trusted application using docker compose.

## Prerequisites

- Docker
- Docker Compose
- An AMD SEV-SNP enabled machine (for secure mode)

## Build demo artifacts

From git repo root, run ./build.sh.

## Update Stage0 Measurement for SNP machine only

In appraisal_policy.textproto for secure mode, the stage0 measurement varies for
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

If the application is running correctly, you should see the following output:

```
Hello from inside the trusted application!
```

## Files

- `docker-compose.yaml`: Docker compose configuration for secure mode (requires AMD SEV-SNP).
- `insecure-docker-compose.yaml`: Docker compose configuration for insecure mode (does not require AMD SEV-SNP).
- `run.sh`: A script to check for AMD SEV-SNP support and launch the appropriate docker compose configuration.
- `appraisal-policy.prototext`: Security policy for the trusted application in secure mode.
- `insecure-appraisal-policy.prototext`: Security policy for the trusted application in insecure mode.
- `test.sh`: A script to test the application.
