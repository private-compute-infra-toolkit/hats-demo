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

VCPU_COUNT=2
DEMO_DIR=$(readlink -f "$(dirname $0)")
SETUP_DIR="$DEMO_DIR/_setup"
mkdir -p $SETUP_DIR
setup_tvs_appraisal_policy() {
  pushd $SETUP_DIR
  git clone https://github.com/virtee/sev-snp-measure $SETUP_DIR/sev-snp-measure
  mkdir -p /tmp/system_bundle
  tar -xf $DEMO_DIR/ba_hats_stack/system_bundle.tar -C /tmp/system_bundle
  local STAGE0_MEASUREMENT=$(./sev-snp-measure/sev-snp-measure.py --ovmf=/tmp/system_bundle/stage0_bin \
            --mode=snp \
            --vcpu-family=`cat /proc/cpuinfo | grep "cpu family" | uniq | cut -d ':' -f 2 | cut -d " " -f 2` \
            --vcpu-model=`cat /proc/cpuinfo | grep "model" | grep -v name | uniq | cut -d ':' -f 2 | cut -d ' ' -f 2` \
            --vcpu-stepping=`cat /proc/cpuinfo | grep "stepping"  | uniq | cut -d ':' -f 2 | cut -d ' ' -f 2` \
            --vcpus $VCPU_COUNT)
  rm -rf /tmp/system_bundle
  if [[ $(command -v cargo) ]];
    then echo 'Cargo is already installed';
  else
      curl https://sh.rustup.rs -sSf | sh;
  fi

  git clone https://github.com/virtee/snphost.git
  pushd ./snphost/
  cargo build
  local SNP_STR=$(sudo target/debug/snphost show tcb)
  local SNP=$(echo $SNP_STR | grep -oP 'SNP: \K\d+' | head -n 1)
  local BOOT_LOADER=$(echo $SNP_STR | grep -oP 'Boot Loader: \K\d+' | head -n 1)
  local MICROCODE=$(echo $SNP_STR | grep -oP 'Microcode: \K\d+' | head -n 1)
  popd
  popd

  echo "Please replace the corresponding fields in ./tvs/appraisal_policy.prototext"
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
}

setup_tvs_appraisal_policy
