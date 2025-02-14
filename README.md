# HATs Demo

This repository contains demos for running applications using the HATs stack.

## Host requirements 

In our demo, we have 3 devices but you can run the demo in a single device if it satisfies the requirement.
1. Terminal, such as your MacOS laptop.
  - Access to both the Build machine and Test machine.
2. Build machine
  - >=128GiB RAM
  - Internet connection
3. Test machine
  - >=32GiB RAM 
  - AMD SEV-SNP enabled CPU EPYC 7003 or newer
  - Linux Kernel Version 6.11.0 or newer
  - Internet connection
  - CentOS stream 10 distro

For reference, we built the demo on a gLinux rodete ( debian ) server with 128GiB RAM, and copied to
the test machine through
`scp <build machine address>:~/demo.tar <test machine address>:~/demo.tar`. Our 
test machine has AMD EPYC 7313P CPU with 64GiB RAM.
It runs CentOS Stream 10 with kernel version `6.11.0-27.el10.x86_64`.

## Setup SEV-SNP feature on Test machine

You need to turn on SEV-SNP feature in the Test machine. You can refer to [Using SEV with AMD EPYC Processors](https://www.amd.com/content/dam/amd/en/documents/epyc-technical-docs/tuning-guides/58207-using-sev-with-amd-epyc-processors.pdf) for instructions for your specific machine model.

For reference, we are using EPYC 7313P and Supermicro H12SSL-I motherboard, and
our BIOS version is:

```
Vendor: American Megatrends Inc.
Version: 3.0
Release Date: 07/22/2024
BIOS Revision: 5.22
```

In our case, the BIOS setup goes as following:

```
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

Once BIOS is setup, you can boot into the OS and run `sudo sevctl ok snp` to
check if the SEV-SNP feature is turned on properly. You should see the following if it's properly setup. Otherwise, please refer to AMD EPYC manual to try turning on the SEV-SNP feature again.

```
$ sudo sevctl ok snp
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

Once the setup is complete, please proceed to the demo folders.
