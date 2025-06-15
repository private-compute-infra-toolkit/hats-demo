ARG image_digest=sha256:f528891ab1aa484bf7233dbcc84f3c806c3e427571d75510a9d74bb5ec535b33
FROM debian:bookworm-slim@${image_digest}

WORKDIR /
COPY ./__run.sh ./run.sh
COPY ./tvs-server_main /tvs-server_main

ENTRYPOINT ["./run.sh"]
