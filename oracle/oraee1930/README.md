# Overview

download Oracle Database 19c (19.3) for Linux x86-64 from https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html

- Build Oracle EE image


```bash
cd oraee
git clone https://github.com/oracle/docker-images oracle-docker-images
pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -v 19.3.0 -e -o '--build-arg SLIMMING=false'
./buildContainerImage.sh -v 21.3.0 -e -o '--build-arg SLIMMING=false'
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

Oracle EE archive logs are already set in the default dockerfile

- redo is at `/opt/oracle/oradata/ORCL/`
- archive redo is at `/opt/oracle/oradata/ORCL/archive_logs`
- below is `ls` of the Oracle's `/opt/oracle/oradata/ORCL` dir


```
bash-4.2$ ls /opt/oracle/oradata/ORCL/*
/opt/oracle/oradata/ORCL/control01.ctl  /opt/oracle/oradata/ORCL/redo03.log    /opt/oracle/oradata/ORCL/undotbs01.dbf
/opt/oracle/oradata/ORCL/control02.ctl  /opt/oracle/oradata/ORCL/sysaux01.dbf  /opt/oracle/oradata/ORCL/users01.dbf
/opt/oracle/oradata/ORCL/redo01.log     /opt/oracle/oradata/ORCL/system01.dbf
/opt/oracle/oradata/ORCL/redo02.log     /opt/oracle/oradata/ORCL/temp01.dbf

/opt/oracle/oradata/ORCL/ORCLPDB1:
sysaux01.dbf  system01.dbf  temp01.dbf  undotbs01.dbf  users01.dbf

/opt/oracle/oradata/ORCL/archive_logs:
1_6_1136251733.dbf  1_7_1136251733.dbf  1_8_1136251733.dbf

/opt/oracle/oradata/ORCL/pdbseed:
sysaux01.dbf  system01.dbf  temp012023-05-08_01-32-02-508-AM.dbf  undotbs01.dbf
```