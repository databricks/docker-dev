# Overview

Start a 3 node CockroachDB cluster.

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose stop
docker compose logs -f
docker compose exec cockroach bash
```

# References

NOTE: CockroachDB as the source using snapshot replication mode works.  

These instructions assume base environment is already setup from the [README.md](README.md).

- Start CockroachDB

This is a copy/paste from [Start a Cluster in Docker (Insecure) in Mac](https://www.cockroachlabs.com/docs/stable/start-a-local-cluster-in-docker-mac.html) with the following change(s):
  - use `arcnet` instead of `roachnet`

```
export PGCLIENTENCODING='utf-8'
psql postgresql://root:password@cockroach-1:26257/?sslmode=disable
psql "postgresql://$CRL_USER:$CRL_PASS@$CRL_HOST:26257/defaultdb?sslmode=verify-full&sslrootcert=./root.crt"
```