ARG image_digest=sha256:f528891ab1aa484bf7233dbcc84f3c806c3e427571d75510a9d74bb5ec535b33
FROM debian:bookworm-slim@${image_digest}

RUN apt-get update && apt-get install -y curl xz-utils gcc git python3 python3-pip pkg-config libglib2.0-dev git flex bison libssl-dev asciidoctor
RUN pip3 install ninja --break-system-packages

# Install qemu
RUN mkdir /qemu && curl -s -L https://download.qemu.org/qemu-9.2.0-rc3.tar.xz | tar xJ -C /qemu
WORKDIR /qemu/qemu-9.2.0-rc3
RUN ./configure --enable-kvm --target-list="x86_64-softmmu"
RUN make -j32
RUN make install

# Get the QEMU binary only to the second stage.
# iptables / iproute2 are for manipulating internal namespace routing rules.
# dnsmasq is for providing dns resolution to CVM.
# note that dnsmasq is optional because we can tune the iptables rules but that
# makes it more environment dependent.
FROM debian:bookworm-slim@${image_digest}
RUN apt update && apt install -y libglib2.0-0 iptables iproute2 dnsmasq
COPY --from=0 /usr/local/bin/qemu-system-x86_64 /usr/local/bin/qemu-system-x86_64

WORKDIR /
COPY launcher_main /launcher_main
COPY __run.sh /run.sh
COPY dnsmasq.conf /etc/dnsmasq.conf
ENTRYPOINT ["./run.sh"]
