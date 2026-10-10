FROM golift/unpackerr:latest AS src
FROM scratch
COPY --chmod=755 --from=src /unpackerr /unpackerr
ENTRYPOINT ["/unpackerr"]
