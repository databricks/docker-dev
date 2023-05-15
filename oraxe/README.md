# Overview

- Build Oracle XE image

```bash
cd oraxe
git clone https://github.com/oracle/docker-images oracle-docker-images
pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 

./buildContainerImage.sh -v 18.4.0 -x
./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
./buildContainerImage.sh -v 11.2.0.2 -x -o '--build-arg SLIMMING=false'

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
docker compose exec -it oraxe bash

mkdir /opt/oracle/oradata/XE/arch

 sqlplus sys/Passw0rd@XE as sysdba 
-- set archive
alter system set log_archive_dest_1='LOCATION=/opt/oracle/oradata/XE/arch' scope=both;
select destination,STATUS from v$archive_dest where statuS='VALID';
archive log list;

shutdown immediate
startup mount
alter database archivelog;
ALTER DATABASE FORCE LOGGING;
alter database open;


-- online redo current size and location 
select group#,sequence#,bytes,archived,status from v$log;
select group#, member from v$logfile order by group#, member;

-- add 8GB redo
alter database add logfile group 4 '/opt/oracle/oradata/XE/redo04.log' size 8G;
alter database add logfile group 5 '/opt/oracle/oradata/XE/redo05.log' size 8G;
alter database add logfile group 6 '/opt/oracle/oradata/XE/redo06.log' size 8G;

-- switch to the new 8GB redo
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
alter system checkpoint;

--- drop the small redos
alter database drop logfile group 1; 
alter database drop logfile group 2; 
alter database drop logfile group 3;

-- bounce
shutdown immediate
```

login in again
```
docker compose exec -it oraxe sqlplus sys/Passw0rd@XE as sysdba 
startup mount
alter database archivelog;
alter database open;

-- archive log all 
alter system archive log all;
archive log list
```




kill user
```
SELECT SID, SERIAL#, STATUS, SERVER FROM V$SESSION WHERE USERNAME = 'C##ARCSRC';
ALTER SYSTEM KILL SESSION '1101, 31201';