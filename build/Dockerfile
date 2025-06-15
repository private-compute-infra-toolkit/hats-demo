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

# Install nix
RUN apt-get update
RUN apt-get install -y nix rsync sudo gettext git python3
RUN echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf

# Install Bazel
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 -o /usr/local/bin/bazel
RUN chmod +x /usr/local/bin/bazel
RUN bazel --version

# In submodules, allow safe directory.
RUN git config --global --add safe.directory '*'

# Optsuser is for hermetic python bazel modules that require non-root to execute.
RUN useradd -ms /bin/bash optsuser

COPY ./build-hats.sh /build-hats.sh
