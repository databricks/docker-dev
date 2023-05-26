Use Docker UI or below to get the ports
```bash
echo UI http://$(docker compose port ui 8080)
echo Workloads http://$(docker compose port workloads 7681)
```

# to change the arcion binary

generate the docker volume with the binary

```bash
bin/create_arcion_bin_volume.sh https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.31.21.zip

bin/create_arcion_bin_volume.sh https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.04.30.7.zip

bin/create_arcion_bin_volume.sh https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.04.30.9.zip

docker volume ls | grep arcion-bin
```

edit [docker-compose.yaml](./docker-compose.yaml) to use the volume

change the run
```yaml
    volumes:
      - arcion-bin-23033116:/arcion
```    

change the volume
```yaml
volumes:
  arcion-bin-23030115:
    external: true
  arcion-bin-23033116:
    external: true
  arcion-metadata:
```