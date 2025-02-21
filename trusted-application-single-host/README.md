# Hats Demo - Trusted Application on-prem

## Overview

This document outlines the steps to set up and run a demonstration of a Trusted Application using
the Hats framework. This demo showcases an example of running a simple fully measured trusted server
within a Hardware Attested Trusted Execution Environment (TEE) on a local machine. The demo utilizes
local attestation through a Trusted VM Server (TVS).

The Trusted Application here is a simple echo server that receives an encrypted message, and echoes
back the message only if it can attest and retrieve the encryption key from the TVS. When we spin up
the TVS, we can store secrets for a user. For this demo the secret we are storing is the app_key
which is also the decryption key used by the Trusted Application running in the CVM. We also spin up
a Trusted Application Client in this demo that connects to the Trusted Application via the ip
address defined in the launcher_config and uses the app_key to encrypt messages that it sends to the
CVM.

## Prerequisites

-   **Build Machine:** A machine capable of generating the demo folder with necessary scripts and
    the Hats and B&A stacks.
-   **Test Machine (SEV-SNP Device):** A machine with a SEV-SNP enabled processor to run the demo in
    a secure and attested environment.

## Demo Setup

### Build the Demo Folder

On your build machine, execute the following script to generate the `demo` folder, which contains
all required setup scripts, Hats stack, and B&A stack components.

```bash
./build.sh
```

**build.sh Details:**

This script performs the following actions:

1.  **Prepare Demo Directory:**
    -   Creates a `demo` directory.
    -   Copies the contents of the `skeleton` directory into the `demo` directory.
2.  **Update Submodules:**
    -   Updates the Git submodules for the `hats` and `bidding-auction-server` components.
    -   In the `hats` submodule, it checks out a specific commit hash
        (`8abb7e99106e4cc1af1cc5433657fd98e617bf8f`) to ensure a stable demo environment.
3.  **Build Hats Stack:**
    -   Navigates to the `components/hats/client/scripts/` directory.
    -   Builds the Hats launcher, TVS, test key generator, and the Trusted Application runtime
        bundle using the `build-lib.sh` script.
    -   Builds Oak containers for stage0, stage1, kernel, syslogd, and Hats containers.
    -   Creates a `tar` archive of the built components.
    -   Moves the built binaries to the `demo/ta_hats_stack/`, `demo/tvs/` and `demo/` directories.
4.  **Build Trusted Application Client:**
    -   Navigates to the `components/hats/clients/scripts/` directory.
    -   Builds the Trusted Application Client using the `build-lib.sh` script.
5.  **Package Demo:**
    -   Creates a tar archive of the `demo` directory.
    -   Generates a SHA256 checksum of the archive.

### Prepare the Test Machine

Transfer the generated `demo` folder from the build machine to the test machine (the SEV-SNP
device). You can use `scp` to do copying.

### Setup the Environment on the Test Machine

On the test machine, navigate to the `demo` folder and run the setup script.

```bash
cd demo
./setup.sh
```

**setup.sh Details:**

This script performs the following actions:

1.  **Environment Setup:**
    -   Sets the `VCPU_COUNT` to 1.
    -   Defines the `DEMO_DIR`, `TEST_CLIENT_DIR`, and `SETUP_DIR` variables.
    -   Creates the `SETUP_DIR` if it doesn't exist.
2.  **Setup Bazel:**
    -   Checks if Bazel is installed. If not, installs it using `bazelisk` and creates the necessary
        symlink.
3.  **Setup QEMU:**
    -   Checks if QEMU is installed. If not, installs it using `yum`, `pip`, and `wget`.
    -   Downloads and builds QEMU from source.
    -   Installs QEMU to `/usr/local/bin`.
4.  **Setup Host Machine:**
    -   Loads the `vhost_vsock` kernel module.
    -   Installs `sevctl` and `libcurl-devel` using `dnf`.
    -   Checks for SNP support using `sevctl`. Exits if the host does not support SNP.
5.  **Setup TVS Keys:**
    -   Generates noise KK keys, HPKE keys, and authentication keys using the `key-gen` tool.
    -   Stores the generated keys in the appropriate files in the `tvs` and `ta_hats_stack`
        directories.
6.  **Setup TVS Appraisal Policy:**
    -   Clones the `sev-snp-measure` and `snphost` repositories from GitHub.
    -   Generates the stage0 measurement using the `sev-snp-measure.py` script, based on the system
        bundle and the host's CPU information.
    -   Retrieves the SNP, Boot Loader, and Microcode versions using `snphost`.
    -   Outputs the `appraisal_policy.prototext` content with the retrieved values.

### Launch the Local TVS

In the `tvs` folder, execute the following scripts:

```bash
cd tvs
./launch-tvs.sh
```

### Launch the Trusted Application Stack

The demo utilizes the HATs stack to run a Trusted Application packaged as a runtime bundle

```bash
./launch-stack.sh
```

### 7. Run the Trusted Application Client

```bash
./trusted_application_client_main --address=192.168.111.12:8080 --app_key="$(cat tvs/tvs_hold_private_hpke_key_hex)"
```

**Expected output:**

```json
Hello from inside the trusted application!
```
