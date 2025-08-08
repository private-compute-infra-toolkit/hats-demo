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

set -e

# Initialize a variable to hold the vCPU count.
VCPU_COUNT=""

# Loop through all the arguments provided to the script.
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --vcpus)
            if [[ -n "$2" ]]; then
                VCPU_COUNT="$2"
                shift 2 # Move past the option and its value
            else
                echo "Error: Argument for --vcpus is missing." >&2
                exit 1
            fi
            ;;
        *)
            # Handle unknown options
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if the VCPU_COUNT variable was set.
# If it's still empty, the --vcpu flag was not provided.
if [[ -z "$VCPU_COUNT" ]]; then
    echo "Error: Required argument --vcpus is not provided." >&2
    echo "Usage: $0 --vcpus <number>" >&2
    exit 1
fi

# Define the path to the file you want to check.
FILE_PATH="/system_bundle.tar"

# Check if the file does NOT exist or is not a regular file.
# The '-f' operator checks if a path exists and is a regular file.
# The '!' negates the result, so the block runs if the check is false.
if [ ! -f "$FILE_PATH" ]; then
    # Print an error message to standard error (stderr).
    echo "Error: Required file '$FILE_PATH' not found." >&2

    # Exit the script with a non-zero status code to indicate failure.
    exit 1
fi

# If the script reaches this point, the file exists.
echo "File '$FILE_PATH' found. Proceeding..."

mkdir /tmp/system_bundle
tar -xf $FILE_PATH -C /tmp/system_bundle
STAGE0_MEASUREMENT=$(sev-snp-measure --ovmf=/tmp/system_bundle/stage0_bin \
          --mode=snp \
          --vcpu-family=`cat /proc/cpuinfo | grep "cpu family" | uniq | cut -d ':' -f 2 | cut -d " " -f 2` \
          --vcpu-model=`cat /proc/cpuinfo | grep "model" | grep -v name | uniq | cut -d ':' -f 2 | cut -d ' ' -f 2` \
          --vcpu-stepping=`cat /proc/cpuinfo | grep "stepping"  | uniq | cut -d ':' -f 2 | cut -d ' ' -f 2` \
          --vcpus $VCPU_COUNT)
SNP_STR=$(snphost show tcb)
SNP=$(echo $SNP_STR | grep -oP 'SNP: \K\d+' | head -n 1)
BOOT_LOADER=$(echo $SNP_STR | grep -oP 'Boot Loader: \K\d+' | head -n 1)
MICROCODE=$(echo $SNP_STR | grep -oP 'Microcode: \K\d+' | head -n 1)

echo "Please replace stage0_measurement to match machine specific SEV SNP config"
cat << EOF
stage0_measurement {
  amd_sev {
    sha384: "$STAGE0_MEASUREMENT"
    min_tcb_version {
      boot_loader: $BOOT_LOADER
      snp: $SNP
      microcode: $MICROCODE
    }
  }
}
EOF
