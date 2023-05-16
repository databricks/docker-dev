# Overview

## Build Oracle Contaner image

```bash
cd oraee
git clone https://github.com/oracle/docker-images oracle-docker-images
```

-  build oracle image for local consumption

```bash
cd oracle-docker-images/OracleDatabase/SingleInstance/dockerfiles 
./buildContainerImage.sh -f -v 23.2.0   # will build oracle/database:21.3.0-xe 
./buildContainerImage.sh -x -v 21.3.0   # will build oracle/database:23.2.0-free
./buildContainerImage.sh -x -v 18.4.0   # does not work
```

- EE requires download from OTN

- RAC requires EE + download from OTN