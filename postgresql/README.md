# Overview

- Start service

```bash
docker compose up -d

while [ -z "$( docker compose logs postgresql 2>&1 | grep 'database system is ready to accept connections' )" ]; do echo sleep 10; sleep 10; done;

docker compose exec -it postgresql sh -c "apt update && apt install -y postgresql-15-wal2json postgresql-contrib"
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
docker compose exec postgresql bash
```

# References

