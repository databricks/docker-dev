Docker compose of zookeeper and broker from https://developer.confluent.io/quickstart/kafka-docker/

The following are modifications:

- change the `9092` port to random on host side

- add at the end from the official example:

```bash
networks:
  default:
    name: arcnet
    external: true
```