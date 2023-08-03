ARG NOMAD_VERSION=1.6.1

FROM hashicorp/nomad:${NOMAD_VERSION}

LABEL org.opencontainers.image.authors="Clément Dubreuil <clement@dubreuil.dev>" \
      org.opencontainers.image.source="https://github.com/clementd64/docker-nomad" \
      org.opencontainers.image.version=$NOMAD_VERSION \
      org.opencontainers.image.title="Nomad" \
      maintainer="Clément Dubreuil <clement@dubreuil.dev>"

RUN addgroup -S nomad && \
    adduser -S -G nomad nomad && \
    mkdir -p /nomad/config /nomad/data && \
    chown -R nomad:nomad /nomad

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

USER nomad:nomad

CMD ["agent"]
