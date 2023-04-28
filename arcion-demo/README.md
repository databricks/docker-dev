Use Docker UI or below to get the ports
```bash
echo UI http://$(docker compose port ui 8080)
echo Workloads http://$(docker compose port workloads 7681)
```