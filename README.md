# HATs Demo

This repository contains demos for running applications using the HATs stack.

## Setup

---

### Hardware requirements

Our demo uses 3 "devices", but you can run the demo in a single device if satisfies the following
requirement.

-   Terminal, such as your MacOS laptop.

    -   Access to both the Build machine and Test machine.

-   Build machine

    -   RAM `>=128GiB`
    -   Internet connection

-   Test machine

    -   RAM `>=32GiB`
    -   AMD SEV-SNP enabled CPU `EPYC 7003` or newer
    -   Linux Kernel Version `6.11.0` or newer
    -   Internet connection
    -   CentOS stream 10

For reference, we built the demos on a gLinux rodete ( debian ) server with 128GiB RAM, and copied
the `demo.tar` file to the test machine through

```
scp <build machine address>:~/demo.tar \
    <test machine address>:~/demo.tar
```

We tested the demo on two different test machines as following.

### Setup SEV-SNP feature on Test machine

You need to turn on AMD SEV-SNP feature on the Test machine. You can refer to
[Using SEV with AMD EPYC Processors](https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/tuning-guides/58207-using-sev-with-amd-epyc-processors.pdf)
for instructions for your specific machine model. We have two reference test machines.

#### AMD EPYC 7313P, Supermicro H12SSL-I motherboard

OS release: `CentOS Stream 10`, kernel `6.11.0-27.el10.x86_64`

BIOS version:

```bash
Vendor: American Megatrends Inc.
Version: 3.0
Release Date: 07/22/2024
BIOS Revision: 5.22
```

In BIOS setting, turn on the following bits for enabling SMEE ( Secure Memory Encryption ) and
IOMMU, set allowed number of SEV VMs, and turn on SNP.

```bash
Advanced -->
    CPU Configuration -->
        SMEE -> Enabled
        SEV ASID Count -> 509 ASIDs
        SEV-ES ASID Space Limit Control -> Manual
        SEV-ES ASID Space Limit -> 100
        SNP Memory Coverage -> Enabled
    NB Configuration ->
        IOMMU -> Enabled
        SEV-SNP support -> Enable
```

The above setting allows up to 100 SEV, and 409 SEV-SNP or SEV-ES VM guests on the host.

#### AMD EPYC 9124, Dell 067N9T motherboard

OS release: `CentOS Stream 10`, kernel `6.12.0-32.el10.x86_64`

BIOS version:

```bash
Vendor: Dell Inc.
Version: 1.8.3
Release Date: 04/02/2024
BIOS Revision: 1.8
```

In BIOS setting, turn on the following bits for enabling SMEE ( Secure Memory Encryption ) and
IOMMU, set allowed number of SEV VMs, and turn on SNP.

```bash
System BIOS Settings -->
    Processor Settings -->
        Secure Memory Encryption -> Enabled
        Minimum SEV non-ES ASID -> 500
        Secure Nested Paging -> Enabled
        SNP Memory Coverage -> Enabled
```

### Verify SEV-SNP setup

Once SEV-SNP is turned on in BIOS, boot into the OS and install `sevctl`. This requires rust cargo
[installation](https://doc.rust-lang.org/cargo/getting-started/installation.html) and
[sevctl dependencies](https://github.com/virtee/sevctl?tab=readme-ov-file#building).

For reference, on CentOS Stream 10, we did:

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y . "$HOME/.cargo/env"
sudo dnf install -y gcc openssl-devel pkg-config perl perl-FindBinperl-File-Compare
git clone https://github.com/virtee/sevctl.git
cd sevctl
cargo build --release
sudo sevctl ok snp
```

Executing the last step `sudo sevctl ok snp`, should show you all areas have passed.

```bash
[ PASS ] - AMD CPU
[ PASS ]   - Microcode support
[ PASS ]   - Secure Memory Encryption (SME)
[ PASS ]   - Secure Encrypted Virtualization (SEV)
[ PASS ]     - Encrypted State (SEV-ES)
[ PASS ]     - Secure Nested Paging (SEV-SNP)
[ PASS ]       - VM Permission Levels
[ PASS ]         - Number of VMPLs: 4
[ PASS ]     - Physical address bit reduction: 4
[ PASS ]     - C-bit location: 51
[ PASS ]     - Number of encrypted guests supported simultaneously: 253
[ PASS ]     - Minimum ASID value for SEV-enabled, SEV-ES disabled guest: 254
[ PASS ]     - SEV enabled in KVM: enabled
[ PASS ]     - SEV-ES enabled in KVM: enabled
[ PASS ]     - Reading /dev/sev: /dev/sev readable
[ PASS ]     - Writing /dev/sev: /dev/sev writable
[ PASS ]   - Page flush MSR: ENABLED
[ PASS ] - KVM supported: API version: 12
[ PASS ] - Memlock resource limit: Soft: 8388608 | Hard: 8388608
```

## Support

---

We provide support through creating issues on this repository. Please reach out to use through that
avenue.

## License

---

[Apache 2.0 License](./LICENSE) for more information.
