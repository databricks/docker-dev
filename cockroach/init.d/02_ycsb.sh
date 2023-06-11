#!/usr/bin/env bash

ycsb_create_postgres() {
echo "ycsb create postgres" >&2    
cat <<'EOF'
CREATE TABLE IF NOT EXISTS THEUSERTABLE (
    YCSB_KEY INT PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT,
    FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT,
    FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT,
    TS TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6)
); 
CREATE INDEX IF NOT EXISTS THEUSERTABLE_TS ON THEUSERTABLE(TS);

-- SOURCE TRIGGER

CREATE OR REPLACE FUNCTION UPDATE_TS()
RETURNS TRIGGER AS $$
BEGIN
    NEW.TS = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END; 
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER UPDATE_TS_ON_THEUSERTABLE BEFORE UPDATE ON THEUSERTABLE FOR EACH ROW EXECUTE PROCEDURE UPDATE_TS();
EOF
}

ycsb_load() {
    local ROLE=${1}
    local DB_ARC_USER=${2} 
    local DB_ARC_PW=${3} 
    local DB_DB=${4} 
    local SIZE_FACTOR=${5}
    set -x
    
    export PGPASSWORD=${DB_ARC_PW}
    ycsb_create_postgres | psql --username ${DB_ARC_USER}${SIZE_FACTOR} --no-password 

    seq 0 $(( 1000000*${SIZE_FACTOR:-1} - 1 )) | \
        psql --username ${DB_ARC_USER}${SIZE_FACTOR} --no-password \
        -c "copy theusertable (ycsb_key) from STDIN" 

    set +x
}
# 1M, 10M and 100M rows
ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB}  

if [ -z "${ARCDEMO_DEBUG}" ]; then
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 10
    ycsb_load SRC ${SRCDB_ARC_USER} ${SRCDB_ARC_PW} ${SRCDB_DB} 100
fi
