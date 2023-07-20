# crate asciinema video

## Setup asciinema

1. install asciinema:

    ```bash
    sudo apt-get install asciinema
    ```

2. start recording:

    ```bash
    asciinema rec
    ```

3. run commands that will be recorded:

    For exmaple:

    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/arcionlabs/docker-dev/HEAD/install.sh)"
    ```

4. stop and upload:

- stop `asciinema rec`

    ```bash
    exit
    ```
- press `<enter>` to upload to [https://asciinema.org/](https://asciinema.org/)

## At `asciinema.org`

1. link accounts if not already done
   
2. change title to "Source To Destination Replication Workloads"
    For exmaple
    ```bash
    MySQL to PostgresSQL Full TPCC,YCSB
    ```
3. change idle timing to `.5` sec
  
## asciinema to gif

https://github.com/asciinema/agg

sudo apt-get install cargo
cargo install --git https://github.com/asciinema/agg


# create terminalizer gif

```
sudo apt install npm
sudo npm install -g terminalizer
terminalizer record demo
```
