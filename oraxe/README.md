# Overview

- Build Oracle XE image

```bash
cd oraxe
git clone https://github.com/oracle/docker-images oracle-docker-images
pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
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

enable archivelog

```
alter system set log_archive_dest_1='LOCATION=/opt/oracle/oradata/XE/arch' scope=both;

archive log list

select destination,STATUS from v$archive_dest where statuS='VALID';


/opt/oracle/oradata/XE/redo03.log

         2
/opt/oracle/oradata/XE/redo02.log

         1
/opt/oracle/oradata/XE/redo01.log

alter database add logfile group 4 '/opt/oracle/oradata/XE/redo04.log' size 8G;
alter database add logfile group 5 '/opt/oracle/oradata/XE/redo05.log' size 8G;
alter database add logfile group 6 '/opt/oracle/oradata/XE/redo06.log' size 8G;

alter system switch logfile;
alter system switch logfile;
alter system switch logfile;

alter system archive log group 1;
 alter system archive log group 2;
 alter system archive log group 3;
 
select group#, status from v$log;

alter database drop logfile group 1; 
alter database drop logfile group 2; 
alter database drop logfile group 3;

-- For checkpoint
alter system checkpoint;
-- For clear archive log
alter system archive log all;
-- Check status
select group#, thread#, sequence#, status, archived from v$log;

