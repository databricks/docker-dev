
# Manual Setup

Setup Arcion License

```bash
export ARCION_LICENSE="$(cat replicant.lic | base64)"
if [ -z "${ARCION_LICENSE}" ]; then echo "ERROR: ARCION_LICENSE is blank"; fi
echo "${ARCION_LICENSE}" | base64 -d
```

Clone this repo

```bash
git clone https://github.com/arcionlabs/docker-dev 
cd docker-dev
git fetch
```

Docker setup

```bash
# network for contianer communications
docker network create arcnet

# oracle volume for native redo 
docker volume create oraxe11g
docker volume create oraxe2130
docker volume create oraee1930
```

# Using the Demo Kit via CLI

Assume you are in `docker-dev` directory for the below commands.

Start the Demo Kit and couple of data source and destinations.

```bash
# start the demo kit
docker compose -f arcion-demo/docker-compose.yaml up -d

# start MySQL, PostgresSQL, Open Source Kafka and Minio
docker compose -f mysql/docker-compose.yaml up -d
docker compose -f postgresql/docker-compose.yaml up -d
docker compose -f kafka/docker-compose.yaml up -d
docker compose -f minio/docker-compose.yaml up -d
```
