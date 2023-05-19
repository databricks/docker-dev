# Overview

NOTE: WIP

- Start service

```bash
docker compose up -d
```      

- Common introspection commands

```bash
docker compose down
docker compose logs -f
docker compose exec db2 bash
```

# References

https://hub.docker.com/r/ibmcom/db2

[install as non root](
https://www.ibm.com/docs/en/dscp/10.1.0?topic=SSSNY3_10.1.0/com.ibm.db2.luw.qb.server.doc/doc/t0050571.htm)

client install


```
chmod a+r ~
mkdir ~/sqllib
export JAVA_OPTS=-Djava.library.path=lib

cd /opt
mkdir db2
cd db2
gzip -dc /scripts/v11.5.4_linuxx64_client.tar.gz | tar -xvf -
cd client
db2setup

``` 


```
To start using the DB2 instance "rslee", you must set up the DB2 instance environment by sourcing db2profile (for Bourne or Korn shell) or db2cshrc (for C shell) in the sqllib directory with the command ". $HOME/sqllib/db2profile" or "source $HOME/sqllib/db2cshrc". $HOME represents the home directory of the DB2 instance. You can also open a new login window of the DB2 instance user.

Optional steps:

To validate your installation files, instance, and database functionality, run the Validation Tool, /home/rslee/sqllib/bin/db2val. For more information, see "db2val" in the DB2 Information Center.

Open First Steps by running "db2fs" using a valid user ID such as the DB2 instance owner's ID. You will need to have DISPLAY set and a supported web browser in the path of this user ID.

You should ensure that you have the correct license entitlements for DB2 products and features installed on this machine. Each DB2 product or feature comes with a license certificate file (also referred to as a license key) that is distributed on an Activation CD, which also includes instructions for applying the license file. If you purchased a base DB2 product, as well as, separately priced features, you might need to install more than one license certificate. The Activation CD for your product or feature can be downloaded from Passport Advantage if it is not part of the physical media pack you received from IBM. For more information about licensing, search the Information Center (http://publib.boulder.ibm.com/infocenter/db2luw/v10r5/index.jsp) using terms such as "license compliance", "licensing" or "db2licm".

To use your DB2 database product, you must have a valid license. For information about obtaining and applying DB2 license files, see  http://pic.dhe.ibm.com/infocenter/db2luw/v10r5/topic/com.ibm.db2.luw.qb.server.doc/doc/c0061199.html.

Refer to "What's New" http://publib.boulder.ibm.com/infocenter/db2luw/v10r5/topic/com.ibm.db2.luw.wn.doc/doc/c0052035.html in the DB2 Information Center to learn about the new functions for DB2 11.5.4.0.

Some features, such as OS-based authentication, DB2 High Availability, and configuring the DB2 Advanced Copy Services (ACS) are available only in root installations. Also, reserving service names for TCP/IP remote connection or DB2 Text Search is available only in root installations. To enable these features and abilities in non-root installations, run the db2rfe script as the root user with a configuration file. See /home/rslee/sqllib/instance/db2rfe.cfg for an example of the configuration file.

Review the response file created at /home/rslee/db2client_nr.rsp.  Additional information about response file installation is available in the DB2 documentation under "Installing DB2 using a response file".
```