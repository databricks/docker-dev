# Overview

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
docker compose exec oskbroker bash
```

# References

Docker compose of zookeeper and broker from https://developer.confluent.io/quickstart/kafka-docker/

The following are modifications:

- add at the end from the official example:

```bash
networks:
  default:
    name: arcnet
    external: true
```