-- make sure combined does not exceed the master size of 100G
create database ${DB_DB} on master = '40G' LOG ON master = '20G' WITH OVERRIDE
go

sp_addlogin ${DB_ARC_USER}, ${DB_ARC_PW}, ${DB_DB}
go

master..sp_dboption ${DB_DB}, 'select into/bulkcopy/pllsort', true
go

-- add user into the database for the login
use ${DB_DB}
go

sp_adduser ${DB_ARC_USER}
go
grant all to ${DB_ARC_USER}
go
sp_role 'grant', sa_role, ${DB_ARC_USER}
go
sp_role 'grant', replication_role, ${DB_ARC_USER}
go
sp_role 'grant', sybase_ts_role, ${DB_ARC_USER}
go