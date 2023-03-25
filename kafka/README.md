Docker compose of zookeeper and broker from https://developer.confluent.io/quickstart/kafka-docker/

The following was added at the end from the official example:

```bash
networks:
  default:
    name: arcnet
    external: true
```