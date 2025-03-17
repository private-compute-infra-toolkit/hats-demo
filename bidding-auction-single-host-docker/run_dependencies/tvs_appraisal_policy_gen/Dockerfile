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

RUN apt-get update && apt-get install -y curl python3 gcc libssl-dev pkg-config
RUN curl -LO https://github.com/virtee/sev-snp-measure/archive/refs/tags/v0.0.11.tar.gz
RUN tar -xf v0.0.11.tar.gz
RUN ln -s /sev-snp-measure-0.0.11/sev-snp-measure.py /usr/local/bin/sev-snp-measure

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
RUN . "$HOME/.cargo/env" && cargo install --version 0.5.0 snphost
RUN ln -s /root/.cargo/bin/snphost /usr/local/bin/snphost

COPY __docker.sh /run.sh

ENTRYPOINT ["/run.sh"]
