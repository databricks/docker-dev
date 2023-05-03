Use Docker UI or below to get the ports
```bash
echo UI http://$(docker compose port ui 8080)
echo Workloads http://$(docker compose port workloads 7681)
```

# to change the arcion binary

```
- set the docker volume name

generate the docker volume with the binary

```bash
function create_arcion_bin_volume () {
    local ARCION_BIN_URL=$1
    [ -z "${1}" ] && echo "please enter URL as param." && return 1
    local VER=$(echo $ARCION_BIN_URL | sed 's/.*cli-\(.*\)\.zip$/\1/' | sed 's/\.//g')
    docker volume create arcion-bin-$VER
    docker run -it --rm -v arcion-bin-$VER:/arcion -e ARCION_BIN_URL="$ARCION_BIN_URL" alpine sh -c '\
    cd /arcion;\
    wget $ARCION_BIN_URL;\
    unzip -q *.zip;\
    mv replicant-cli/* .;\
    rm -rf replicant-cli/;\
    rm *.zip;\
    chown -R 1000 .;\
    ls\
    '
}
```

create the volumes

```bash
create_arcion_bin_volume https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.31.16.zip

create_arcion_bin_volume https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.03.01.15.zip
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