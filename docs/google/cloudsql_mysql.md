
# Setup Google CloudSQL MySQL

- click Google Cloud -> Create a Database -> Create Instance
- MySQL -> Choose MySQL
- Enable API if asked
- Type instand id - pg8sand
- Type password
- Choose MySQL 8.0
- Choose Cloud SQL Edition Enterprise
- Choose sandbox ($0.14 per hour)
- Choose us-central (default)
- Choose singleZone
- Choose customize your instance
- Click data protection
  - uncheck Enable Delete Protection
- Click flags
  - `cloudsql.logical_decoding on`
  - `cloudsql.enable_pglogical on`
- Create instance


Once the instance comes up

- click connection
- click networking
- click add network
- name: xxx
- network. xx.xx.xx.xx
- click save


to get you ip from home internet try
[whatismyipaddress](https://whatismyipaddress.com/).com


Test from local mysql client

```
mysql -u root -h 34.123.167.223 --password=Passw0rdmy8sand
```

wait couple of minutes.  jot down the following

```
export SRCDB_HOST=34.123.167.223
export SRCDB_TYPE=mysql
export SRCDB_DIR=mysql
export SRCDB_PW=Passw0rdmy8sand

arcdemo.sh full $SRCDB_HOST mysql

unset SRCDB_HOST SRCDB_TYPE SRCDB_DIR SRCDB_PW

export DSTDB_HOST=34.123.167.223
export DSTDB_TYPE=mysql
export DSTDB_DIR=mysql
export DSTDB_PW=Passw0rdmy8sand
arcdemo.sh full mysql $DSTDB_HOST

unset DSTDB_HOST DSTDB_TYPE DSTDB_DIR DSTDB_PW



```
takes about 5 min to load the data

# TODO



# References

