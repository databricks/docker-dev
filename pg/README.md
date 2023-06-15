# Overview

- Start service

For pg v15 (latest)
```bash
docker compose --build
docker compose up -d
```      

For pg v13
```bash
docker compose -f docker-compose-v14.yaml --build
docker compose up -f docker-compose-v14.yaml -d
```      

For pg v13
```bash
docker compose -f docker-compose-v13.yaml --build
docker compose up -f docker-compose-v13.yaml -d
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
docker compose exec postgresql bash
```

# References

