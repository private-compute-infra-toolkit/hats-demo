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

ARG image_digest=sha256:f528891ab1aa484bf7233dbcc84f3c806c3e427571d75510a9d74bb5ec535b33
FROM debian:bookworm-slim@${image_digest}

RUN apt-get update && apt-get install -y curl xz-utils iproute2 net-tools
# Install qemu
RUN mkdir /qemu && curl -s -L https://download.qemu.org/qemu-9.2.0-rc3.tar.xz | tar xJ -C /qemu
WORKDIR /qemu/qemu-9.2.0-rc3
RUN apt-get install -y gcc git python3 python3-pip pkg-config libglib2.0-dev git flex bison libssl-dev asciidoctor
RUN pip3 install ninja --break-system-packages
RUN ./configure --enable-kvm --enable-slirp --target-list="x86_64-softmmu"
RUN make -j32
RUN make install
# linker cache flush so that qemu binary can work.
RUN rm /etc/ld.so.cache
RUN ldconfig

WORKDIR /
COPY . .
