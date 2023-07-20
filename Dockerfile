FROM debian:bullseye-slim as download

# This is the release of nomad to pull in.
ARG NOMAD_VERSION=1.6.0

# This is the location of the releases.
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

# Set up certificates, base tools, and nomad.
# libc6-compat is needed to symlink the shared libraries for ARM builds
RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget curl gnupg openssl unzip && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys C874011F0AB405110D02105534365D9472D7468F && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    arch="$(uname -m)" && \
    case "${arch}" in \
        aarch64) nomadArch='arm64' ;; \
        armhf) nomadArch='arm' ;; \
        x86) nomadArch='386' ;; \
        x86_64) nomadArch='amd64' ;; \
        *) echo >&2 "error: unsupported architecture: ${arch} (see ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/)" && exit 1 ;; \
    esac && \
    wget ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_${nomadArch}.zip && \
    wget ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS && \
    grep nomad_${NOMAD_VERSION}_linux_${nomadArch}.zip nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /tmp/build nomad_${NOMAD_VERSION}_linux_${nomadArch}.zip && \
    gpgconf --kill all && \
    # tiny smoke test to ensure the binary we downloaded runs
    /tmp/build/nomad version

FROM debian:bullseye-slim

LABEL org.opencontainers.image.authors="Clément Dubreuil <clement@dubreuil.dev>" \
      org.opencontainers.image.source="https://github.com/clementd64/docker-nomad" \
      org.opencontainers.image.version=$NOMAD_VERSION \
      org.opencontainers.image.title="nomad"

# Create a nomad user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup --system nomad && \
    adduser --system nomad

# Set up certificates, base tools, and nomad.
# libc6-compat is needed to symlink the shared libraries for ARM builds
RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget curl dumb-init && \
    rm -rf /var/lib/apt/lists/* && \
# The /nomad/data dir is used by Nomad to store state. The agent will be started
# with /nomad/config as the configuration directory so you can add additional
# config files in that location.
    mkdir -p /nomad/data && \
    mkdir -p /nomad/config && \
    chown -R nomad:nomad /nomad

# set up nsswitch.conf for Go's "netgo" implementation which is used by nomad,
# otherwise DNS supercedes the container's hosts file, which we don't want.
RUN test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf

COPY --from=download /tmp/build/nomad /bin/nomad

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

USER nomad:nomad

CMD ["agent", "-dev", "-bind", "0.0.0.0"]