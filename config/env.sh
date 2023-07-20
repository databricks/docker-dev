# DEBUG
ARCDEMO_DEBUG=1
# column and row databaes
# column ycsb initial dataset is setup to compress 10x
#                  Column               Row
#           DELTATABLE  USERTABLE   DELTATABLE  USERTABLE
#   1       2M          159M        20M         1.6G
#   10      25M         1.6G        250M        16.7G
#   100     250M        17G         2.5G        161G
#   1000    2.4G                    20.4G
ARCDEMO_COL_DELTA_SF=100      
ARCDEMO_ROW_DELTA_SF=100

ARCDEMO_COL_USER_SF=10         
ARCDEMO_ROW_USER_SF=1          

# DB for heartbeat table 
REPLICANT_DB=io_replicate
# Replicant user / password 
REPLICANT_USER=replicant
REPLICANT_PW=Replicant#123

# create separate DB for these db names
DBS_COMMA=arcsrc
ARCDEMO_DB_NAMES=auctionmarks,epinions,seats

# standard id and passwords
SRCDB_ARC_USER=arcsrc
SRCDB_ARC_PW=Passw0rd
SRCDB_DB=arcsrc

DSTDB_ARC_USER=arcdst
DSTDB_ARC_PW=Passw0rd
DSTDB_DB=arcdst

# confluent
CFLT_SRC_ID=${CFLT_SRC_ID:-changeme}
CFLT_SRC_SECRET=${CFLT_SRC_SECRET:-changeme}
CFLT_SRC_ENDPOINT=${CFLT_SRC_ENDPOINT:-changeme}

CFLT_DST_ID=${CFLT_DST_ID:-changeme}
CFLT_DST_SECRET=${CFLT_DST_SECRET:-changeme}
CFLT_DST_ENDPOINT=${CFLT_DST_ENDPOINT:-changeme}

# minio
MINIO_SRC_ID=${MINIO_SRC_ID:-changeme}
MINIO_SRC_SECRET=${MINIO_SRC_SECRET:-changeme}
MINIO_SRC_ENDPOINT=${MINIO_SRC_ENDPOINT:-changeme}

MINIO_DST_ID=${MINIO_DST_ID:-changeme}
MINIO_DST_SECRET=${MINIO_DST_SECRET:-changeme}
MINIO_DST_ENDPOINT=${MINIO_DST_ENDPOINT:-changeme}

# Snowflake
SNOW_SRC_ID=${SNOW_SRC_ID:-changeme}
SNOW_SRC_SECRET=${SNOW_SRC_SECRET:-changeme}
SNOW_SRC_ENDPOINT=${SNOW_SRC_ENDPOINT:-changeme}
SNOW_SRC_WAREHOUSE=${SNOW_SRC_WAREHOUSE:-changeme}

SNOW_DST_ID=${SNOW_DST_ID:-changeme}
SNOW_DST_SECRET=${SNOW_DST_SECRET:-changeme}
SNOW_DST_ENDPOINT=${SNOW_DST_ENDPOINT:-changeme}
SNOW_DST_WAREHOUSE=${SNOW_DST_WAREHOUSE:-changeme}

# Google Big Query the key is gzip | base64 -w 0
GBQ_SRC_LOCATION=${GBQ_SRC_LOCATION:-changeme}
GBQ_SRC_SECRET=${GBQ_SRC_SECRET:-changeme}
GBQ_SRC_ENDPOINT=${GBQ_SRC_ENDPOINT:-changeme}

GBQ_DST_LOCATION=${GBQ_DST_LOCATION:-changeme}	
GBQ_DST_SECRET=${GBQ_DST_SECRET:-changeme}
GBQ_DST_ENDPOINT=${GBQ_DST_ENDPOINT:-changeme}
# AWS
AWS_SRC_ID=${AWS_SRC_ID:-changeme}
AWS_SRC_SECRET=${AWS_SRC_SECRET:-changeme}

AWS_DST_ID=${AWS_DST_ID:-changeme}
AWS_DST_SECRET=${AWS_DST_SECRET:-changeme}  

# ###################################################
# s3 end points

# google cloud storage (GCS)
GCS_DST_ID=${GCS_DST_ID:-changeme}
GCS_DST_SECRET=${GCS_DST_SECRET:-changeme}
GCS_DST_ENDPOINT=${GCS_DST_ENDPOINT:-https://storage.googleapis.com}
GCS_DST_BUCKET=${GCS_DST_BUCKET:-arcdst}

# wasabi (bucket name must be lower case)
# https://wasabi-support.zendesk.com/hc/en-us/articles/360015106031-What-are-the-service-URLs-for-Wasabi-s-different-regions-
WASABI_DST_ID=${WASABI_DST_ID:-changeme}
WASABI_DST_SECRET=${WASABI_DST_SECRET:-changeme}
WASABI_DST_ENDPOINT=${WASABI_DST_ENDPOINT:-https://s3.wasabisys.com}
WASABI_DST_BUCKET=${WASABI_DST_BUCKET:-arcdst}
WASABI_DST_REGION=${WASABI_DST_REGION:-us-east-1}

# storj (bucket name must be lower case)
STORJ_DST_ID=${STORJ_DST_ID:-changeme}
STORJ_DST_SECRET=${STORJ_DST_SECRET:-changeme}
STORJ_DST_ENDPOINT=${STORJ_DST_ENDPOINT:-https://gateway.storjshare.io}
STORJ_DST_BUCKET=${STORJ_DST_BUCKET:-arcdst}
