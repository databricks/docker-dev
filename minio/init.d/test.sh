mc alias set localS3 http://minio:9000

mc alias set --api "S3v4" myminiov4 http://localhost:9000 minioadmin minioadmin

mc alias set --api "S3v2" myminiov2 http://localhost:9000 minioadmin minioadmin


https://min.io/docs/minio/linux/integrations/aws-cli-with-minio.html

aws configure
AWS Access Key ID [None]: Q3AM3UQ867SPQQA43P2F
AWS Secret Access Key [None]: zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG
Default region name [None]: us-east-1
Default output format [None]: ENTER
Additionally enable AWS Signature Version ‘4’ for MinIO server.

aws configure set default.s3.signature_version s3v4
4. Commands
To list your buckets
aws --endpoint-url https://play.min.io:9000 s3 ls
2016-03-27 02:06:30 deebucket
2016-03-28 21:53:49 guestbucket
2016-03-29 13:34:34 mbtest
2016-03-26 22:01:36 mybucket
2016-03-26 15:37:02 testbucket

Enable TLS
https://min.io/docs/minio/linux/operations/network-encryption.html?ref=docs-redirect


AWS CLI

pip install awscli-plugin-endpoint
aws configure set plugins.endpoint awscli_plugin_endpoint
aws configure set plugins.cli_legacy_plugin_path /home/arcion/.local/lib/python3.10/site-packages
aws configure --profile default set s3.endpoint_url http://minio:9000

