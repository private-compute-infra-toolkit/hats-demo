#!/bin/bash
# Copyright 2024 Google LLC
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

# This is required because different machine may have different SNP specific microcode etc.
generate_machine_specific_appraisal_policy() {
  set -e
  echo '===== Check SNP support ====='
  snphost ok
  # 'We fix the VCPU_COUNT to 2 to avoid different stage0_measurement.'
  local VCPU_COUNT=2
  mkdir -p /tmp/system_bundle
  tar -xf /output/system_bundle.tar -C /tmp/system_bundle
  local STAGE0_MEASUREMENT=$(sev-snp-measure --ovmf=/tmp/system_bundle/stage0_bin \
            --mode=snp \
            --vcpu-family=`cat /proc/cpuinfo | grep "cpu family" | uniq | cut -d ':' -f 2 | cut -d " " -f 2` \
            --vcpu-model=`cat /proc/cpuinfo | grep "model" | grep -v name | uniq | cut -d ':' -f 2 | cut -d ' ' -f 2` \
            --vcpu-stepping=`cat /proc/cpuinfo | grep "stepping"  | uniq | cut -d ':' -f 2 | cut -d ' ' -f 2` \
            --vcpus $VCPU_COUNT)
  local SNP_STR=$(snphost show tcb)
  local SNP=$(echo $SNP_STR | grep -oP 'SNP: \K\d+' | head -n 1)
  local BOOT_LOADER=$(echo $SNP_STR | grep -oP 'Boot Loader: \K\d+' | head -n 1)
  local MICROCODE=$(echo $SNP_STR | grep -oP 'Microcode: \K\d+' | head -n 1)

  echo "Replacing stage0_measurement in /workspace/appraisal_policy.prototext to match machine specific SEV SNP config"
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

  sed -i "s/sha384:.*/sha384:\ \"$STAGE0_MEASUREMENT\"/g" /conf/appraisal_policy.prototext
  sed -i "s/boot_loader:.*/boot_loader:\ $BOOT_LOADER/g" /conf/appraisal_policy.prototext
  sed -i "s/snp:.*/snp:\ $SNP/g" /conf/appraisal_policy.prototext
  sed -i "s/microcode:.*/microcode:\ $MICROCODE/g" /conf/appraisal_policy.prototext
}

generate_machine_specific_appraisal_policy
