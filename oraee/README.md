# Overview

download Oracle Database 19c (19.3) for Linux x86-64 from https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html

- Build Oracle EE image


```bash
cd oraee
git clone https://github.com/oracle/docker-images oracle-docker-images
pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'
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

