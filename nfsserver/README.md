# overview

```
export NFS_SERVER=$(docker network inspect arcnet -f '{{ json .IPAM}}' | jq -r '.Config | .[] | .Subnet | split("/") | .[0] | split(".") | .[0:3] | join(".")').254
```

if any of the followng are changeed

docker compose down
docker image rm nfsserver-nfsserver
docker container prune
docker compose up -d

NFS directory structure

```bash
/oradata/xe/11g 1000
/oradata/xe/2130 54321
/oradata/ee/11930 54321
/oradata/rac/2130 54321
```

need for nfs
want nfs 3 and 4 
https://github.com/ehough/docker-nfs-server has support
https://phoenixnap.com/kb/nfs-docker-volumes has instruction to follow
https://blog.stefandroid.com/2021/03/03/mount-nfs-share-in-docker-compose.html easy easy exlanation on options


the nfs server required priv
nfs client 

NOTES:
is bridge network needed? no
name can be used in the client instead of hard coded IP of server? no.  IP is required
how about using host.docker.internal and exposing the NFS port no
NFS_SERVER=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nfs)
this works but if the IP of nfs server changes, then volumes won't work anymore

NFS_SERVER=$(docker network inspect -f '{{.Config.subnet}}{{.IPAddress}}{{end}}' nfs)

hard to figure out go template.  switching to jq
only show first three ocets of the subet
export NFS_SERVER=$(docker network inspect arcnet -f '{{ json .IPAM}}' | jq -r '.Config | .[] | .Subnet | split("/") | .[0] | split(".") | .[0:3] | join(".")').254


use --aux-addresses to reserve the IP of the nfs
docker create network and reserve .2
docker network create --subnet=172.20.0.0/16 --aux-address="nfs=172.20.0.2" test1  hmm. cannot figure out how to assign this to the container
to automate this, need to look at existing bridge netowrk and pick a subnet not used
what is the 

test 1
install nfs on the host docker 
$ showmount -e
Export list for ovo:
/home/rslee/nfsshare *

host's IP address for mounting
export NFS_SERVER=$(hostname -i)

create docker volume w/NFS

docker volume create --driver local \
      --opt type=nfs \
      --opt o=nfsvers=4,addr=$NFS_SERVER,rw \
      --opt device=:/home/rslee/nfsshare \
      nfsshare

docker inspect nfsshare
[
    {
        "CreatedAt": "2023-05-13T14:41:36Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/nfsshare/_data",
        "Name": "nfsshare",
        "Options": {
            "device": ":/home/rslee/nfsshare",
            "o": "nfsvers=4,addr=172.23.40.208,rw",
            "type": "nfs"
        },
        "Scope": "local"
    }
]

docker run -it --rm \
    --mount type=volume,dst=/container/path,volume-driver=local,volume-opt=type=nfs,"volume-opt=o=nfsvers=4,addr=$NFS_SERVER",volume-opt=device=:/home/rslee/nfsshare  
    nfsshare


apt-get install nfs-common netbase
