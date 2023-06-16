container name, hostname and aliases follow the following convention

A database hostname can have the following names.
The shorter version faciliate easier typing in UI and CLI.
In the demo kit, the shorter names are converted to canonical name automatically.

For example postgres can have the following names:
pg, pg-src, pg-dst, pg-src-version-1, pg-dst-version-1

the following names refere to the same node
- `pg` - short name for on the highest version
- `pg-src` the latest source
- `pg-src-v1503-1` the latest source

the following names refere to the same node
- `pg-dst` the latest source
- `pg-dst-v1503-1`

## container name
each container is identified by database-[src|dst]-version-instance.  
postgres source version 15.03 instance is 
`pg-src-v1503-1`

## hostname
`hostname: pg-src` and ``hostname: pg-src` are used to group database sources and destinations.
For example, pg has v15,v14,and v13 versions.  
Using this convetions `getent hosts pg-src` returns IPs that have `pg-src` hostnames
- pg-src-v15
- pg-src-v14
- pg-src-v13

this helps automate permutation test using the below script

```bash
for src in $(getent hosts pg-src); do
  for dst in $(getent hosts pg-dst); do
    arcdemo full $src $dst
  done
done
```

## aliases
the latest version will have `pg-src` and `pg-dst` to reduce the amount of typing in the UI and CLI.
