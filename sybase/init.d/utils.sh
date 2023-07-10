#!/usr/bin/env bash

. /opt/sybase/SYBASE.sh


if [[ -z "$DATA_VOL" ]]; then 
  export DATA_VOL=$(dirname $0)
  echo "Warning: DATA_VOL not defined. Saving log the $DATA_VOL" >&2
fi

if [[ ! -d "$DATA_VOL" ]]; then
  mkdir -p $DATA_VOL
  echo "Warning: DATA_VOL did not exist.  created $DATA_VOL" >&2
fi

export INITDB_LOG_DIR=$DATA_VOL/initdb_log

if [[ ! -d "$INITDB_LOG_DIR" ]]; then
  mkdir -p $INITDB_LOG_DIR
  echo "Warning: INITDB_LOG_DIR did not exist.  created $INITDB_LOG_DIR" >&2
fi

if [[ -z "$INITDB_DIR" ]]; then 
  export INITDB_DIR=/docker-entrypoint-initdb.d
fi

heredoc_file() {
    # heredoc on a file
    eval "$( echo -e '#!/usr/bin/env bash\ncat << EOF_EOF_EOF' | cat - $1 <(echo -e '\nEOF_EOF_EOF') )"    
    # TODO: a way to capture error code from here
}

cli_arcsrc() {
    local DB_ARC_USER=${1:-${DB_ARC_USER:-${SRCDB_ARC_USER:-arcsrc}}}
    local DB_ARC_PW=${2:-${DB_ARC_PW:-${SRCDB_ARC_PW:-Passw0rd}}}
    local DB_DB=${3:-${DB_DB:-${SRCDB_DB:-${DB_SRC_USER}}}}

    isql -U ${DB_ARC_USER} -P ${DB_ARC_PW} -S $SYBASE_SID
}

cli_arcdst() {
    local DB_ARC_USER=${1:-${DB_ARC_USER:-${DSTDB_ARC_USER:-arcdst}}}
    local DB_ARC_PW=${2:-${DB_ARC_PW:-${DSTDB_ARC_PW:-Passw0rd}}}
    local DB_DB=${3:-${DB_DB:-${DSTDB_DB:-${DB_SRC_USER}}}}

    isql -U ${DB_ARC_USER} -P ${DB_ARC_PW} -S $SYBASE_SID
}

cli_replicant() {
    isql -U ${REPLICANT_USER:-replicant} -P ${REPLICANT_PW:-"Replicant#123"} -S $SYBASE_SID
}

cli_root() {
    isql -U $SYBASE_ROOT -P  $SYBASE_PASSWORD -S $SYBASE_SID 
}

sf_to_name() {
    if [[ "${1}" = "1" ]]; then echo ""; else echo ${1}; fi
}