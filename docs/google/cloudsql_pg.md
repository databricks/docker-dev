
# Setup Google CloudSQL Postgres

- click Google Cloud -> Create a Database -> Create Instance
- PostgreSQL -> Choose PostgreSQL
- Enable API if asked
- Type instand id - pg15sand
- Type password
- Choose postgres 15
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

wait couple of minutes.  jot down the following

public IP 35.223.192.210

SRCDB_HOST=35.223.192.210

psql -U postgres -h $SRCDB_HOST

# TODO

1. diff among pg_hba.conf

```
allow remote replication connection from any client machine  to <username> (IPv4 + IPv6)
host     replication          <username>    0.0.0.0/0                        <auth-method>
host     replication          <username>    ::0/0  
```
```

`host replication all all md5` is only required for [pg 9.6 and earlier](https://cloud.google.com/sql/docs/postgres/replication/configure-logical-replication#:~:text=PostgreSQL%20supports%20logical%20decoding%20by,setting%20used%20in%20standard%20PostgreSQL)    

arcion requires the following to be [set](https://docs.arcion.io/docs/source-setup/postgresql/#iii-set-up-connection-configuration)

```

# References

https://cloud.google.com/sql/docs/postgres/replication/configure-logical-replication#configure-your-postgresql-instance  