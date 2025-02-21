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

VCPU_COUNT=2
DEMO_DIR=$(readlink -f "$(dirname $0)")
TEST_CLIENT_DIR="$DEMO_DIR/test_client"
SETUP_DIR="$DEMO_DIR/_setup"
mkdir -p $SETUP_DIR

setup_docker() {
  if [[ $(command -v docker) ]] then
    echo 'Docker is already installed';
    return 0
  fi

  curl -LO https://download.docker.com/linux/centos/10/x86_64/stable/Packages/containerd.io-1.7.25-3.1.el10.x86_64.rpm
  curl -LO https://download.docker.com/linux/centos/10/x86_64/stable/Packages/docker-buildx-plugin-0.19.3-1.el10.x86_64.rpm
  curl -LO https://download.docker.com/linux/centos/10/x86_64/stable/Packages/docker-ce-27.5.0-1.el10.x86_64.rpm
  curl -LO https://download.docker.com/linux/centos/10/x86_64/stable/Packages/docker-ce-cli-27.5.0-1.el10.x86_64.rpm
  curl -LO https://download.docker.com/linux/centos/10/x86_64/stable/Packages/docker-ce-rootless-extras-27.5.0-1.el10.x86_64.rpm
  curl -LO https://download.docker.com/linux/centos/10/x86_64/stable/Packages/docker-compose-plugin-2.32.4-1.el10.x86_64.rpm
  sudo dnf install -y *.rpm
  sudo systemctl start docker
  sudo docker run --rm busybox ping 8.8.8.8 -c 2
}

setup_bazel() {
  if [[ $(command -v bazel) ]] then
    echo 'Bazel is already installed';
    return 0
  fi

  wget https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64
  chmod +x bazelisk-linux-amd64
  sudo mv bazelisk-linux-amd64 /usr/local/bin/bazelisk-linux-amd64
  sudo ln -s /usr/local/bin/bazelisk-linux-amd64 /usr/local/bin/bazel
  bazel --version
}

setup_qemu() {
  if [[ $(command -v qemu-system-x86_64) ]] then
    echo 'QEMU is already installed';
    return 0
  fi

  # QEMU
  sudo yum install -y gcc git glib2-devel libfdt-devel pixman-devel zlib-devel bzip2 python3
  pip install ninja
  wget https://download.qemu.org/qemu-9.2.0-rc3.tar.xz
  tar xvJf qemu-9.2.0-rc3.tar.xz
  pushd qemu-9.2.0-rc3
  ./configure --enable-kvm --enable-slirp --target-list="x86_64-softmmu"
  make -j32
  echo 'Installing QEMU 9.2.0 rc3'
  sudo make install
  popd
  qemu-system-x86_64 --version
}

setup_host() {
  # Setup the host SNP machine and make sure it works good.
  sudo modprobe vhost_vsock
  # Setup dependencies
  # Required by using curl-config to find CA locally.
  sudo dnf install -y sevctl libcurl-devel
  SNP_CHECK=$(sudo sevctl ok snp)
  echo "$SNP_CHECK"
  if [[ "$SNP_CHECK" == *"FAIL"* ]]; then
    echo "STOP because the host machine doesn't support SNP"
    exit 1
  fi
}

setup_test_client() {
  pushd $TEST_CLIENT_DIR
  git clone https://github.com/privacysandbox/bidding-auction-servers
  git clone https://github.com/privacysandbox/bidding-auction-local-testing-app.git
  pushd bidding-auction-local-testing-app
  sudo ./setup
  popd
  cat << EOF
Please add bidding-auction-local-testing-app/certs/localhost.pem file as a trusted SSL certificate in your system. On Mac, this requires going to KeyChain.
EOF
  popd
}

setup_tvs_keys() {
  pushd $DEMO_DIR
  # The script generates keys for B&A onprem public demo.
  # shellcheck disable=SC2002
  echo 'Generating Noise KK Keys'
  echo '0000000000000000000000000000000000000000000000000000000000000001' > tvs/tvs_hold_noise_kk_private_key_hex
  # uncompressed public key generated with P256 from the noise_kk private key.
  echo '04a99c16a302716404b075086c8c125ea93d0822330f8a46675c8f7e5760478024811211845d43e6addae5280660ba3b5ba0f78834b79ec9449b626a725728b76d' > ba_hats_stack/orchestrator_hold_noise_kk_public_key_hex
  echo 'Generating HPKE keys'
  HPKE_KEYS=$(./key-gen --key-type=x25519-hkdf-sha256)
  echo $HPKE_KEYS | awk '{split($0,a," "); print a[2]}' > tvs/public_hold_public_hpke_key_hex
  echo $HPKE_KEYS | awk '{split($0,a," "); print a[4]}' > tvs/tvs_hold_private_hpke_key_hex
  echo 'Generating Auth keys'
  AUTH_KEYS=$(./key-gen --key-type=secp128r1)
  echo $AUTH_KEYS | awk '{split($0,a," "); print a[2]}' > tvs/tvs_hold_user_authentication_public_key_hex
  echo $AUTH_KEYS | awk '{split($0,a," "); print a[4]}' > ba_hats_stack/launcher_hold_user_authentication_private_key_hex
  popd

}

setup_tvs_appraisal_policy() {
  local $VCPU_COUNT = "$1"
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

setup_host
setup_docker
setup_bazel
setup_qemu
setup_test_client
setup_tvs_keys
