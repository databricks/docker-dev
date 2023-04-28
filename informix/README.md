# Overview

NOTE: If you are not in the current directory as the `docker-compose.yaml` file, then use `-f` to indicate the location of the file.  For exmaple,  `docker compose -f informix/docker-compose.yaml up -d`  Use the same pattern for the other commands.  

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
docker compose exec informix bash
```

# References

more info from IBM at 
https://github.com/informix/informix-dockerhub-readme
