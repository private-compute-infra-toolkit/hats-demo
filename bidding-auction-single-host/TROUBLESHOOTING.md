# Troubleshooting Guide for Hats Demo - Bidding and Auction on-prem

## Bidding and Auction (B&A) Launch Issues

### Appraisal Policy Mismatch

If you encounter the following error message after launching a B&A service (e.g.,
`./launch-ba.sh stack_a/auction.prototext`):

```
I0204 09:53:22.104661 2198360 logs-service.cc:55] oak-orchestrator.service: Error: couldn't get tvs client: "error from tvs server: Error status: Unknown, message: \"Failed to read from stream. Invalid or malformed command. UNKNOWN: Failed to verify report. No matching appraisal policy found\", details: [], metadata: MetadataMap { headers: {} }"
```

This indicates that the required appraisal policy is missing or does not match the current
configuration. To resolve this, follow these steps:

1.  **Identify the Missing Policy:** Examine the QEMU log output for the following section:

    ```
    stage0 INFO: Expected number of APs: 1, started number of APs: 1
    stage0 DEBUG: Initial RAM disk size 5998258
    stage0 DEBUG: Initial RAM disk address 0x000000003fa47000
    stage0 DEBUG: Kernel image digest: sha2-256:eca5ef41f6dc7e930d8e9376e78d19802c49f5a24a14c0be18c8e0e3a8be3e84
    stage0 DEBUG: Kernel setup data digest: sha2-256:9745b0f42d03054bb49033b766177e571f51f511c1368611d2ee268a704c641b
    stage0 DEBUG: Kernel command-line:  console=ttyS0 panic=-1 brd.rd_nr=1 brd.rd_size=2097152 brd.max_part=1 ip=192.168.84.103::192.168.84.1:255.255.255.0::enp0s1:off quiet -- --launcher-addr=vsock://2:1879495136
    stage0 DEBUG: Initial RAM disk digest: sha2-256:7cd4896bdd958f67a6a85cc1cc780761ac9615bc25ae4436aad1d4e9d2332c1a
    stage0 DEBUG: ACPI table generation digest: sha2-256:10ec82d58dc2471c09f328650dd9d7bd2df0fc5f96ce64cacefadea88dde3aba
    stage0 DEBUG: E820 table digest: sha2-256:e18d171a9468a80446d543cdd5f6d94a25ebd08f7124244106f91373540db9b1
    stage0 DEBUG: Event digest: sha2-256:57575ebf8ebbe9a2a54e01600bb5b3482d36ce4214aa70ff3ea60c8a22834f43
    stage0 INFO: jumping to kernel at 0x0000000002000200
    ```

2.  **Update `tvs/appraisal_policy.prototext`:**

        - **Kernel Image Digest:** Update the `kernel_image_sha256` field in
          `tvs/appraisal_policy.prototext` with the value from `Kernel image

    digest:`line.     - **Kernel Setup Data Digest:** Update the`kernel*setup_data_sha256`      field in`tvs/appraisal_policy.prototext`with the value from the      `Kernel
    setup data
    digest:`line.     - **Kernel Command-Line:** Update the`kernel_cmd_line_regex`field in      `tvs/appraisal_policy.prototext`with the kernel command line. The       command line is the part after`-append`in the QEMU command that the       launcher prints out. For example:`I0204
    10:39:35.250854 2316808 launcher.cc:557] Server listening on 'vsock:2:1879495139' I0204
    10:39:35.250975 2316808 launcher.cc:417] Qemu command:/usr/local/bin/qemu-system-x86_64
    /usr/local/bin/qemu-system-x86_64 -enable-kvm -cpu host -m 4194304k -smp 2 -nodefaults
    -nographic -no-reboot -machin e q35,acpi=on,memory-backend=ram1,confidential-guest-support=sev0
    -object memory-backend-memfd,id=ram1,size=4194304k,share=true,reserve=false -object
    sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1,id-auth =1 -netdev
    tap,id=tap627351049,ifname=tap627351049,script=/tmp/qemu-if-pJtMuh -device
    virtio-net-pci,disable-legacy=on,iommu_platform=true,netdev=netdev,romfile=,netdev=tap627351049,mac=d6:ef:77:16:a5:7b
    -devic e vhost-vsock-pci,guest-cid=273052,rombar=0 -bios /tmp/hats-X58CDAA/stage0_bin -kernel
    /tmp/hats-X58CDAA/kernel_bin -initrd /tmp/hats-X58CDAA/initrd.cpio.xz -append console=ttyS0
    panic=-1 brd.rd_nr=1 brd.rd_si ze=4194304 brd.max_part=1
    ip=192.168.84.101::192.168.84.1:255.255.255.0::enp0s1:off quiet --
    --launcher-addr=vsock://2:1879495139 -serial
    stdio`Pick the part after      `-append`and turn that into a regex for the field.     - **Initial RAM Disk Digest:** Update the`init_ram_fs_sha256`field in      `tvs/appraisal_policy.prototext`with the value from the`Initial
    RAM disk
    digest:`line.     - **ACPI Table Generation Digest:** Update the`acpi_table_sha256`field       in`tvs/appraisal_policy.prototext`with the value from the`ACPI
    table generation
    digest:`line. When you change the`num_cpus`,       `ramdrive_size_kb`, `ram_size_kb`, etc, this value will change.     - **E820 Table Digest:** Update the `memory_map_sha256`field in      `tvs/appraisal_policy.prototext`with the value from the`E820
    table
    digest:`line. When you change the`num_cpus`, `ramdrive_size_kb`,       `ram_size_kb`, etc, this value will change.     - **Container Binary SHA256:** Update the `container_binary_sha256`field       in`tvs/appraisal_policy.prototext`. This field is changed by runc       runtime bundle in `./ba_hats_stack/stack*\*/**/runc_runtime_bundle.tar`.       The content and sha256sum of the tar file will be changed when B&A code       or config is changed. You can get this value from running `sha256sum
    runc_runtime_bundle.tar`. - **System Image SHA256:** Update the `system_image_sha256` field in
    `tvs/appraisal_policy.prototext`. This field is changed by
    `./ba_hats_stack/system_bundle.tar/system.tar.xz`. It'll be changed when the linux system image
    running inside the CVM is changed such as code changes in oak orchestrator or systemctl config
    etc. You can get this value from running
    `mkdir /tmp/system_bundle && tar -xf ./ba_hats_stack/system_bundle.tar -C /tmp/system_bundle && sha256sum /tmp/system_bundle/system.tar.xz`. -
    **Stage0 Measurement:\*\* Update the `stage0_measurement` field in
    `tvs/appraisal_policy.prototext`. This field is changed by running on different machines with
    different CPU or BIOS config. You can get this value from running `./stage0_measurement.sh` in
    the demo folder and paste the result in the appraisal_policy file. Example output:
    ``~/tar/demo/_setup ~/tar/demo fatal: destination path '/home/sidachen/tar/demo/_setup/sev-snp-measure' already exists and is not an empty directory. Cargo is already installed fatal: destination path 'snphost' already exists and is not an empty directory. ~/tar/demo/_setup/snphost ~/tar/demo/_setup ~/tar/demo Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.07s ~/tar/demo/_setup ~/tar/demo ~/tar/demo Please replace the corresponding fields in ./tvs/appraisal_policy.prototext stage0_measurement { amd_sev { sha384: "fe21dd7648c63f0529f05b375c2cd1d00c049cd3fbd752de9ea24f0701e56db7b8a062ebd41fa16a1385213c40af76f8" min_tcb_version { boot_loader: 4 snp: 21 microcode: 213 } } }``

3.  **Restart TVS:** After modifying the `appraisal_policy.prototext`, restart the TVS service for
    the changes to take effect: `bash ./launch-tvs.sh`

### Insufficient Disk Space

If you encounter the following error message:

```
I0204 10:34:15.462473 2302132 logs-service.cc:55] oak-orchestrator.service: Error: failed to unpack `/run/oak_containers_orchestrator/oak_container/rootfs/server/bin/inference_sidecar_tensorflow_v2_14_0`
I0204 10:34:15.462485 2302132 logs-service.cc:55] oak-orchestrator.service: Caused by:
I0204 10:34:15.462493 2302132 logs-service.cc:55] oak-orchestrator.service:     0: failed to unpack `./rootfs/server/bin/inference_sidecar_tensorflow_v2_14_0` into `/run/oak_containers_orchestrator/oak_container/rootfs/server/bin/inference_sidecar_tensorflow_v2_14_0`
I0204 10:34:15.462503 2302132 logs-service.cc:55] oak-orchestrator.service:     1: No space left on device (os error 28)
```

This error indicates that there is insufficient space on the virtual disk. To resolve this:

1.  **Modify `ramdrive_size_kb`:** Increase the value of the `ramdrive_size_kb` parameter in
    launcher configuration file (e.g., `./ba_hats_stack/stack*_/_.prototext`).
2.  **Modify E820 Table Digest and ACPI Table Generation Digest in Appraisal Policy:** Restart the
    B&A service with launcher configuration changed and follow `Appraisal Policy Mismatch` section
    to update the appraisal policy.
3.  **Restart Services:** Restart the TVS, and B&A services with the updated configuration. Note:
    Ensure that the total RAM allocated to the server does not exceed the available memory on your
    system to avoid out-of-memory (OOM) errors.

## BFE/SFE Testing Issues

### Docker Bridge Network Configuration

If you experience build errors when running the `sfe-test.sh` script, it's crucial to verify that
the Docker default bridge network is correctly configured. Specifically, IP Tables must be enabled.
To check this:

1.  **Verify `daemon.json`:** Confirm that the `/etc/docker/daemon.json` file contains the following
    settings:

    ```json
    {
        "ip-forward": true,
        "iptables": true,
        "log-opts": {
            "max-file": "5",
            "max-size": "50m"
        }
    }
    ```

2.  **Enable IP Tables:** If `iptables` is not set to `true`, enable it and restart the Docker
    service.

By addressing these issues, you should be able to successfully launch and test the B&A services
using the Hats demo.

### Invalid OpenSSL error

Symptom: In the case that clicking on "Run single-seller B&A auction" results in an empty Publisher
Site iframe in a while. In bidding-auction-testing-app, check the log and it shows:

```
  code: 3,
  details: 'Error while decrypting protected_auction_ciphertext: Malformed OHTTP encapsulated request provided Failed to decrypt.OpenSSL error: e
rror:1e000065:Cipher functions:OPENSSL_internal:BAD_DECRYPT.',
```

This is caused by Chrome not picking up the latest HPKE public key from the local public key server.
Chrome caches the HPKE encryption key for 1 day for each user profile. You need to restart Chrome
and enter "Guest Profile" again.

## Build Script

If you see get-builder-image-tagged error:

```
Error: get-builder-image-tagged status code: 1
Docker build log: /usr/local/google/home/sidachen/hats-demo/docker-buildx-build-debian-ulGb.log

build_and_test_all_in_docker runtime: 3s
Error: build_and_test_in_docker completed with status code: 1
```

And the build log says:

```
------
ERROR: failed to solve: rpc error: code = Unknown desc = failed to solve with frontend dockerfile.v0: failed to create LLB definition: failed to do request: Head "https://mirror.gcr.io/v2/docker/buildx-bin/manifests/v0.10?ns=docker.io": proxyconnect tcp: dial tcp 127.0.0.1:8080: connect: connection refused
```

**Troubleshooting Steps:**

1.  **Review Docker Proxy Configuration:**
    -   Examine the Docker daemon configuration files:
        -   `/etc/systemd/system/docker.service.d/override.conf`
        -   `/etc/docker/daemon.json`
    -   Verify that the proxy settings are correctly configured and that the specified proxy server
        is active and reachable.
2.  **Check Proxy Server Status:**
    -   Ensure that the proxy server (likely running on `127.0.0.1:8080`) is running without errors.
