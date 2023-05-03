# Overview

- Build Oracle XE image

```bash
cd oraxe
git clone https://github.com/oracle/docker-images oracle-docker-images
pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
popd
```

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
docker compose exec oraxe bash
```

# References

