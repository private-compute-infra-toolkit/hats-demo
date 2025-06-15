#!/bin/bash

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
  ip link
  ip link add dev br0 type bridge
  ip addr add 10.3.3.1/24 dev br0
  ip link set dev br0 up

  # IP networking doesn't account for vsock CID allocation.
  # Expose 10.3.3.2 ( VM address ) through NAT.
  # Run dnsmasq on 10.3.3.1.
  # 2 available implementations and we choose dnsmasq by default.
  # - dnsmasq: better compatibility, but worse reliability.
  # - iptables: better reliability, but may conflict with existing iptables rules.
  #
  # ADDRESS=$(awk '$1=="nameserver"{print $2; exit}' /etc/resolv.conf)
  # echo "nameserver used: $ADDRESS"
  #iptables -t nat -I PREROUTING -d 10.3.3.1 -j DNAT --to-destination $ADDRESS
  #iptables -t nat -A OUTPUT -d 10.3.3.1 -j DNAT --to-destination $ADDRESS
  #iptables -t nat -A POSTROUTING -d $ADDRESS -j MASQUERADE
  #iptables -t nat -A PREROUTING -i eth0 -j DNAT --to-destination 10.3.3.2
  #iptables -t nat -A POSTROUTING -s 10.3.3.2 -o eth0 -j MASQUERADE
  iptables -t nat -A PREROUTING ! -i br0 -j DNAT --to-destination 10.3.3.2
  iptables -t nat -A POSTROUTING -s 10.3.3.2 -j MASQUERADE

  # Prevent duplicates
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

cat /config.prototext > /pv/testout
./launcher_main \
  --tvs_addresses="${TVS_ADDRESSES}" \
  --use_tls=false \
  --launcher_config_path='/config.prototext' \
  --tvs_authentication_key="${TVS_AUTHENTICATION_KEY}" \
  --vmm_log_to_std --minloglevel=0 --stderrthreshold=0
