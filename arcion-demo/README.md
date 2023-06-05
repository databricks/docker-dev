Use Docker UI or below to get the ports
```bash
echo UI http://$(docker compose port ui 8080)
echo Workloads http://$(docker compose port workloads 7681)
```

# Overview

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose stop
docker compose logs -f
docker compose exec workloads tmux attach
```

# References