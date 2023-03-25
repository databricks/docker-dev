
more info at https://github.com/informix/informix-dockerhub-readme/blob/master/14.10.FC1/informix-developer-database.md


```bash
docker compose up -d
```      

```bash
docker compose exec informix bash
```

create arcsrc and arcdst
use mapped user https://www.ibm.com/docs/en/informix-servers/12.10?topic=security-internal-users-unix-linux
create user syntax https://www.ibm.com/docs/en/informix-servers/12.10?topic=statements-create-user-statement-unix-linux

```bash
onmode -wf USERMAPPING=BASIC
sudo useradd -d /home/arcsrc -s /bin/false arcsrc
sudo useradd -d /home/arcdst -s /bin/false arcdst
sudo mkdir /etc/informix
sudo tee /etc/informix/allowed.surrogates <<EOF
USERS:arcsrc
USERS:arcdst
EOF

echo "create user arcsrc with password 'Passw0rd';" | dbaccess
echo "create user arcdst with password 'Passw0rd';" | dbaccess
echo "create database arcsrc with LOG;" | dbaccess
echo "create database arcdst with LOG;" | dbaccess
echo "create schema authorization arcsrc;" | dbaccess arcsrc
echo "grant resource to arcsrc" | dbaccess arcsrc
echo "grant connect to arcsrc" | dbaccess arcsrc
echo "create schema authorization arcdst;" | dbaccess arcdst
echo "grant connect to arcdst" | dbaccess arcdst
echo "grant resource to arcdst" | dbaccess arcdst
onmode -cache surrogates
```

allow remote connection from arcion-demo for arcsrc and arcdst
```
tee -a ~/.rhosts <<EOF
arcsrc
arcdst
EOF
sudo tee -a $INFORMIXDIR/etc/hosts.equiv <<EOF
arcion-demo.arcnet
EOF
```

create table from jsqsh
```
database arcsrc;
create table t1 (arcsrc);


setup remote login
```
vi $INFORMIXDIR/etc/$ONCONFIG

JDBC Driver from https://mvnrepository.com/artifact/com.ibm.informix/jdbc/4.50.10



https://informix-technology.blogspot.com/2009/04/informix-authentication-and-connections.html

https://www.ics.uci.edu/~dbclass/ics184/htmls/Informix_guide.html


docker exec -t ifx
dbaccess
onstat


cd
PATH=/opt/ibm/informix/bin:$PATH
dbaccessdemo

echo "create user arcsrc with password 'Passw0rd';" | dbaccess


https://www.ibm.com/docs/en/informix-servers/12.10?topic=linux-creating-database-server-users-unix





dbaccess - -
database sysuser;
CREATE DEFAULT USER WITH PROPERTIES USER 'guest';

CREATE USER arcdst WITH PASSWORD Passw0rd;
