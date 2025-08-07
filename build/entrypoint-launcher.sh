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

echoerr() { echo "$@" 1>&2; }

# Ensure required environment variables are set.
if [[ -z "${TVS_ADDRESSES}" ||
  -z "${TVS_AUTHENTICATION_KEY}" ||
  -z "${NUM_CPUS}" ||
  -z "${RAMDRIVE_SIZE_KB}" ||
  -z "${RAM_SIZE_KB}" ||
  -z "${RUNC_RUNTIME_BUNDLE}" ||
  -z "${SYSTEM_BUNDLE}"
  ]]; then
  printenv
  echoerr "SYSTEM_BUNDLE / RUNC_RUNTIME_BUNDLE / TVS_ADDRESSES / TVS_AUTHENTICATION_KEY / NUM_CPUS / RAMDRIVE_SIZE_KB / RAM_SIZE_KB is expected to be non-empty"
  exit 1
fi

CVM_TYPE='CVMTYPE_DEFAULT'
if [[ -z "${NO_SNP}" ]]; then
  CVM_TYPE='CVMTYPE_SEVSNP'
fi

setup_network() {
  # This bridge will have an address of 10.3.3.1/24 with dnsmasq setup.
  # The dnsmasq server forwards DNS queries to docker provided ones defined in
  # resolv.conf.
  # The CVM runs on 10.3.3.2 and effectively acts as the container itself
  # through iptables DNAT / MASQUERADE rules.
  ip link add dev br0 type bridge
  ip addr add 10.3.3.1/24 dev br0
  ip link set dev br0 up

  iptables -t nat -A PREROUTING ! -i br0 -j DNAT --to-destination 10.3.3.2
  iptables -t nat -A POSTROUTING -s 10.3.3.2 -j MASQUERADE

  iptables-save | uniq | iptables-restore
  dnsmasq
}

generate_config() {
echo "cvm_config {
  cvm_type: ${CVM_TYPE}
  runc_runtime_bundle: \"${RUNC_RUNTIME_BUNDLE}\"
  hats_system_bundle: \"${SYSTEM_BUNDLE}\"
  vmm_binary: \"/usr/local/bin/qemu-system-x86_64\"
  num_cpus: ${NUM_CPUS}
  ramdrive_size_kb: ${RAMDRIVE_SIZE_KB}
  ram_size_kb: ${RAM_SIZE_KB}
  network_config {
    virtual_bridge {
      virtual_bridge_device: \"br0\"
      cvm_ip_addr: \"10.3.3.2\"
      cvm_gateway_addr: \"10.3.3.1\"
    }
  }
}" > /config.prototext
}

generate_config
setup_network

./launcher_main \
  --tvs_addresses="${TVS_ADDRESSES}" \
  --use_tls=false \
  --launcher_config_path='/config.prototext' \
  --tvs_authentication_key="${TVS_AUTHENTICATION_KEY}" \
  --vmm_log_to_std --minloglevel=0 --stderrthreshold=0
