# Nomad server in Docker

This image provide a thin wrapper around [hashicorp/nomad](https://hub.docker.com/r/hashicorp/nomad) to run a Nomad server.

It use a configuration similar to [hashicorp/consul](https://hub.docker.com/r/hashicorp/consul) and [hashicorp/vault](https://hub.docker.com/r/hashicorp/vault)

:warning: Running agent in client mode is **not** supported.

## Usage

Because running nomad in server mode always require environment specific configuration (like `bootstrap_expect`), the agent is run with server mode disabled by default.

No init process is used. Using the Docker [built-in init process](https://docs.docker.com/engine/reference/run/#specify-an-init-process) is highly recommanded for zombie processes reaping.

```sh
docker run --rm --init ghcr.io/clementd64/nomad:1.6.1 agent -server -bootstrap-expect=1
```

The configuration can also be specified using the `NOMAD_LOCAL_CONFIG` environment variable in hcl or json format

```sh
docker run --rm --init -e NOMAD_LOCAL_CONFIG='{"server": {"enabled": true, "bootstrap_expect": 1}}' ghcr.io/clementd64/nomad:1.6.1
```

The configuration is read from `/nomad/config` (configurable using `NOMAD_CONFIG_DIR`).
The content of `NOMAD_LOCAL_CONFIG` is written into `local.json` in this directory on startup.

Data is stored in `/nomad/data` (configurable using `NOMAD_CONFIG_DIR` environment variable).

The image run as a non root user named `nomad`.

### With docker compose

```yaml
services:
  nomad:
    image: ghcr.io/clementd64/nomad:1.6.1
    hostname: nomad
    init: true
    environment:
      NOMAD_LOCAL_CONFIG: |
        server {
          enabled          = true
          bootstrap_expect = 1
        }
    volumes:
      - nomad-data:/nomad/data
    ports:
      - 4646:4646
      - 4647:4647
      - 4648:4648

volumes:
  nomad-data:
```

## Credits

This image is based on the official Nomad [Docker image](https://github.com/hashicorp/nomad/blob/main/Dockerfile).

The entrypoint script is based on the Consul [entrypoint script](https://github.com/hashicorp/consul/blob/v1.16.0/.release/docker/docker-entrypoint.sh) from the official Docker image.
