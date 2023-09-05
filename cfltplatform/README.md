# Overview

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
```

# References

This was built with the followng:

```bash
curl --silent --output docker-compose.yml \
  https://raw.githubusercontent.com/confluentinc/cp-all-in-one/7.3.3-post/cp-all-in-one/docker-compose.yml
```

The following are modifications:

- add at the end from the official example:

```bash
networks:
  default:
    name: arcnet
    external: true
```