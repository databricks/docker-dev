disk resize name='master', size='100G'
go

sp_cacheconfig "default data cache", "25M"
go

-- master..sp_dboption master 'select into/bulkcopy/pllsort' enable
-- go

sp_addlogin ${DB_ARC_USER}, ${DB_ARC_PW}, master 
go

-- add user into the database for the login
use master
go

sp_adduser ${DB_ARC_USER}
go

grant all to ${DB_ARC_USER}
go
