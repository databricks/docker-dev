These are Docker Compose files used for Data source and Data destination in [Demo Load Generator](https://github.com/arcionlabs/arcion-demo) and Release Testing.
The diagram below depicts the components of the demo kit where where the Docker Compose files fit in.

- Load Generator
- Data source
- Arcion host with dedicated metadata database
- Data destination

```mermaid
graph LR
    L[Load Generator<br>benchbase<br>sysbench<br>YCSB] --> S
    subgraph Arcion Cluster
        A1
        M[(Meta <br>Data)]
    end
    S[(Source <br>Data)] --> A1[Arcion <br> Node 1]
    A1 --> T[(Destination<br>Data)]
```

# Getting started

- Clone this repo

    ```bash
    git clone https://github.com/arcionlabs/docker-dev 
    cd docker-dev
    ```

- Create Docker network

    ```bash
    docker network create arcnet
    ```

- Start one or more of Data source and destinations

  An examaple of starting Kakfa

    ```bash
    cd kakfa
    docker compose up -d
    ```

  An examaple of stopping Kakfa

    ```bash
    cd kakfa
    docker compose down
    ```

  An examaple of logs from Kakfa

    ```bash
    cd kakfa
    docker logs
    ```