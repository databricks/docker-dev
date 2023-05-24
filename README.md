These are Docker Compose files used for Data source and Data destination in [Demo Load Generator](https://github.com/arcionlabs/arcion-demo) and Release Testing.
The diagram below depicts the components of the demo kit where where the Docker Compose files fit in.

- Load Generator
- Data source
- Arcion host with dedicated metadata database
- Data destination

```mermaid
graph LR
    L[Load Generator<br>TPC-C<br>sysbench<br>YCSB] --> S
    subgraph Arcion Cluster
        A1
        M[(Meta <br>Data)]
    end
    S[(Source <br>Data)] --> A1[Arcion <br> UI]
    A1 --> T[(Destination<br>Data)]
```

# Getting started

Assumptions:

- running on Windows WSL, Liunx, Mac (Intel and Apple Silicon)
- have Arcion License
- have Docker 

# One Time Setup  

Setup Arcion License

```bash
export ARCION_LICENSE="$(cat replicant.lic | base64)"
if [ -z "${ARCION_LICENSE}" ]; then echo "ERROR: ARCION_LICENSE is blank"; fi
echo "${ARCION_LICENSE}" | base64 -d
```

Clone this repo

```bash
git clone https://github.com/arcionlabs/docker-dev 
cd docker-dev
git fetch
```

Docker setup

```bash
# network for contianer communications
docker network create arcnet

# oracle volume for native redo 
docker volume create oraxe11g
docker volume create oraxe2130
docker volume create oraee1930
```

# Using the Demo Kit via CLI

Assume you are in `docker-dev` directory for the below commands.

Start the Demo Kit and couple of data source and destinations.

```bash
# start the demo kit
docker compose -f arcion-demo/docker-compose.yaml up -d

# start MySQL, PostgresSQL, Open Source Kafka and Minio
docker compose -f mysql/docker-compose.yaml up -d
docker compose -f postgresql/docker-compose.yaml up -d
docker compose -f kafka/docker-compose.yaml up -d
docker compose -f minio/docker-compose.yaml up -d
```

## Connect to the demo kit

The demo kit uses `tmux`.  Based on your preference, use one or both methods below.  Both views will be in sync.

- using browser: `http://localhost:7681`
- using terminal: `docker exec -it workloads tmux attach`

Generate data and activity for testing using Arcion CLI

- go to http://localhost:7681

each will run for 5 minutes and times out by default

```bash
arcdemo.sh full mysql oskbroker
arcdemo.sh full postgresql minio
arcdemo.sh full postgresql mysql
arcdemo.sh full mysql postgresql
```

### Change Scale Factor Performance and Scale Tests

- For 1GB volume test, change the scale factor to 10

    go to http://localhost:7681

    each will run for 5 minutes and times out by default

    scale factor 10 will generate about 1GB of data on YCSB and 1GB TPC-C

    ```bash
    arcdemo.sh -s 10 full mysql oskbroker
    arcdemo.sh -s 10 full postgresql minio
    arcdemo.sh -s 10 full postgresql mysql
    arcdemo.sh -s 10 full mysql postgresql
    ```

- For 10GB volume test, change the scale factor to 100

    go to http://localhost:7681

    each will run for 5 minutes and times out

    scale factor 100 will generate about 10GB of data on YCSB and 1GB of TPC-C
    set snapshot inter table parallelism to 2 on the extractor and 2 on the applier

    ```bash
    arcdemo.sh -s 100 -b 2:2 full mysql oskbroker
    arcdemo.sh -s 100 -b 2:2 full mysql postgresql
    arcdemo.sh -s 100 -b 2:2 full postgresql mysql
    arcdemo.sh -s 100 -b 2:2 full postgresql oskbroker
    ```

- For stresing out CDC, change the workload update rate and increase threads on Arcion real-time threads

    ```bash
    arcdemo.sh -s 100 -b 2:2 -r 2:2 -t 0 full mysql oskbroker
    arcdemo.sh -s 100 -b 2:2 -r 2:2 -t 0 full mysql postgresql
    arcdemo.sh -s 100 -b 2:2 -r 2:2 -t 0 full postgresql mysql
    arcdemo.sh -s 100 -b 2:2 -r 2:2 -t 0 full postgresql oskbroker
    ```

    `-r 2:2` use 2 threads respectively for Arcion real-time extractor and applier 
    `-t 0`   run YCSB on 1 thread and TPC-C on 1 thread as fast as possible 
    
## To shutdown all data source and destination providers

```bash
for db in $( find * -maxdepth 1 -type d -prune ! -name "arcion*" ); do
pushd $db; docker compose down; popd
done
```

# Use Arcion UI

go to http://localhost:8080 and sign in with user `admin` password `arcion`

# Cloud Database Examples

## Snowflake

- Snowflake source to MySQL destination
use default on mysql destination

single thread each extractor and applier
source catalog is SNOWFLAKE_SAMPLE_DATA and source schema is TPCH_SF1

```bash
SRCDB_DB=SNOWFLAKE_SAMPLE_DATA SRCDB_SCHEMA=TPCH_SF1 arcdemo.sh snapshot snowflake mysql
```

two threads each extractor and applier
source catalog is default `arcsrc` and source schema is `PUBLIC`
```bash
arcdemo.sh -b 2:2 snpashot snowflake mysql
```

# Oracle Docker Setup

Oracle requires container images to be build locally.
Start with Oracle XE, then use Oracle EE for volume testing.
Oracle XE does not require the extra step of download the Oracle EE binary.
Oracle EE should be used for anything scale factor beyond 10.

### Oracle XE

- Build the image

    ```bash
    cd oraxe
    git clone https://github.com/oracle/docker-images oracle-docker-images
    pushd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
    ./buildContainerImage.sh -v 21.3.0 -x -o '--build-arg SLIMMING=false'
    popd
    cd ..
    ```

- Start service

    ```bash
    docker compose -f oraxe/docker-compose.yaml up -d
    ``` 

- A test examples

    Scale factor 10 
    Snapshot inter table parallelism of 2

    ```bash
    arcdemo.sh -s 10 -b 2:2 full oraxe postgresql
    ```