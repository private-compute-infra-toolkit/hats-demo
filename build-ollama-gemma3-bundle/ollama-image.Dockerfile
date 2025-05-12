# debian:bookworm-20250428-slim
ARG debian_snapshot=sha256:4b50eb66f977b4062683ff434ef18ac191da862dbe966961bc11990cf5791a8d
FROM debian@${debian_snapshot}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get --yes update \
    && apt-get install --yes --no-install-recommends \
    ca-certificates curl \
    # Cleanup
    && apt-get clean \
    && rm --recursive --force /var/lib/apt/lists/*

# Clean up several non-deterministic and unneeded files:
#  * /etc/shadow contains the date passwords were generated; set to the same
#    age as root
#  * passwd and shadow backup files can be removed
#  * /var/lib/dbus/machine-id can be a symlink to /etc/machine-id
#  * /etc/machine-id should be missing or empty so that it's generated on boot
#  * various log files can be empty
#  * doc/info/man pages aren't needed
#  * /var/cache/ldconfig/aux-cache can be removed; this is safe for all files
#    in /var/cache
RUN (LAST_DAY="$(awk -F: '$1=="root"{print $3}' /etc/shadow)") \
    && rm -f /etc/{passwd,shadow}- \
    && rm -rf /usr/share/{doc,info,man} /var/cache/ldconfig/aux-cache

# Copy runc entrypoint
COPY --chmod=0755 start-gemma3.sh /usr/bin/

# Install ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

RUN echo 'ollama serve &' >> /tmp/pull-gemma3.sh
RUN echo 'sleep 1' >> /tmp/pull-gemma3.sh
RUN echo 'ollama pull gemma3:1b' >> /tmp/pull-gemma3.sh

# Download gemma3 model
RUN sh -c "sh /tmp/pull-gemma3.sh"
