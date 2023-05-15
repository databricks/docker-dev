

# setup NFS on the docker host itself

sudo apt-get install nfs-kernel-server
sudo systemctl start nfs-kernel-server.service
vi /etc/exports
sudo exportfs -a


```
export NFS_VOL_NAME=mynfs
export NFS_LOCAL_MNT=/opt/oracle/data
export NFS_SERVER=172.23.40.208
export NFS_SHARE=/home/rslee/nfsshare
export NFS_OPTS=vers=4,soft

docker run --mount \
  "src=$NFS_VOL_NAME,dst=$NFS_LOCAL_MNT,volume-opt=device=:$NFS_SHARE,\"volume-opt=o=addr=$NFS_SERVER,$NFS_OPTS\",type=volume,volume-driver=local,volume-opt=type=nfs" \
  busybox ls $NFS_LOCAL_MNT
```  

```
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=172.23.40.208,rw \
  --opt device=:/home/rslee/nfsshare \
  oradata
```

```
docker run -d -it \
  --name test \
  --mount source=oradata,target=/opt/oracle \
  alpine
```  

./buildDockerImage.sh -v 21.3.0

```bash

cd orarac
git clone https://github.com/oracle/docker-images oracle-docker-images

cp ~/github/arcion/arcion-demo/tmp/LINUX.X64_213000_db_home.zip .
cp  LINUX.X64_213000_grid_home.zip

pushd oracle-docker-images/OracleDatabase/RAC/OracleRealApplicationClusters/dockerfiles 

sed -i .bak s/$OLIMAGE?oraclelinux:7-slim/ 21.3.0/Dockerfile

./buildContainerImage.sh -v 21.3.0 -o '--build-arg SLIMMING=true'  # false does not build
popd

```