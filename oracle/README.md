# Overview

## Build Oracle Contaner image

```bash
cd oracle
git clone https://github.com/oracle/docker-images oracle-docker-images
```

- 19.0

## arm64
https://www.oracle.com/database/technologies/oracle19c-linux-arm64-downloads.html

Oracle Database 19c (19.19) for LINUX ARM (aarch64)

[LINUX.ARM64_1919000_db_home.zip](https://download.oracle.com/otn/linux/oracle19c/1919000/LINUX.ARM64_1919000_db_home.zip)
[LINUX.ARM64_1919000_grid_home.zip](https://download.oracle.com/otn/linux/oracle19c/1919000/LINUX.ARM64_1919000_grid_home.zip)
[LINUX.ARM64_1919000_client.zip](https://download.oracle.com/otn/linux/oracle19c/1919000/LINUX.ARM64_1919000_client.zip)
[LINUX.ARM64_1919000_client_home.zip](https://download.oracle.com/otn/linux/oracle19c/1919000/LINUX.ARM64_1919000_client_home.zip)


-  build oracle image for local consumption

```bash
cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -f -v 23.2.0   # will build oracle/database:21.3.0-xe 
./buildContainerImage.sh -x -v 21.3.0   # will build oracle/database:23.2.0-free
./buildContainerImage.sh -x -v 18.4.0   # does not work
```

- EE requires download from OTN

https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html


- RAC requires EE + download from OTN

ubuntu host did not build correctly
failes on slimmingx
https://github.com/oracle/docker-images/issues/1416

```
export DOCKER_BUILDKIT=0
oracle linux 9 as the host
```

- this step can be skipped with NFS storage already created

```bash
cd /home/rslee/github/arcion/docker-dev/oracle/oracle-docker-images/OracleDatabase/RAC/OracleRACStorageServer/dockerfiles
 ./buildDockerImage.sh -v 19.3.0

 export ORACLE_DBNAME=ORCLCDB
docker run -d -t --hostname racnode-storage \
--dns-search=example.com  --cap-add SYS_ADMIN --cap-add AUDIT_WRITE \
--volume /docker_volumes/asm_vol/$ORACLE_DBNAME:/oradata --init \
--network=rac_priv1_nw --ip=192.168.17.25 --tmpfs=/run  \
--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
--name racnode-storage oracle/rac-storage-server:19.3.0

docker volume create --driver local \
--opt type=nfs \
--opt   o=addr=192.168.17.25,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=192.168.17.25:/oradata \
racstorage
```

### DNS

the startip failed

```bash
/home/rslee/github/arcion/docker-dev/oracle/oracle-docker-images/OracleDatabase/RAC/OracleDNSServer/dockerfiles
./buildContainerImage.sh -v latest

docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw

docker run -d  --name racdns \
 --hostname rac-dns  \
 --dns-search="example.com" \
 --cap-add=SYS_ADMIN  \
 --network  rac_pub1_nw \
 --ip 172.16.1.25 \
 --sysctl net.ipv6.conf.all.disable_ipv6=1 \
 --env SETUP_DNS_CONFIG_FILES="setup_true" \
 --env DOMAIN_NAME="example.com" \
 --env RAC_NODE_NAME_PREFIX="racnode" \
 oracle/rac-dnsserver:latest

```

### Connection Manager

download https://www.oracle.com/webapps/redirect/signon?nexturl=https://download.oracle.com/otn/linux/oracle19c/190000/LINUX.X64_193000_client.zip


```bash
cd rslee@ovo:~/github/arcion/docker-dev/oracle/oracle-docker-images/OracleDatabase/RAC/OracleConnectionManager/dockerfiles$
./buildContainerImage.sh -v 19.3.0
