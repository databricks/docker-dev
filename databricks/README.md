





# STEP 4:  Configure ADLS container As Stage

Follow the steps mentioned on below link till “Create Container Step“Connect to Azure Data Lake Storage Gen2 and Blob Storage 

In the Databricks console, click Compute.

In the Advanced Options window, Spark Config

Add following settings

```
spark.hadoop.fs.azure.account.auth.type.<storage-account-name>.dfs.core.windows.net OAuth
spark.hadoop.fs.azure.account.oauth.provider.type.<storage-account-name>.dfs.core.windows.net org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider
spark.hadoop.fs.azure.account.oauth2.client.id.<storage-account-name>.dfs.core.windows.net <application-id>
spark.hadoop.fs.azure.account.oauth2.client.secret.<storage-account-name>.dfs.core.windows.net {{secrets/<secret-scope>/<key stored in secret scope>}}
spark.hadoop.fs.azure.account.oauth2.client.endpoint.<storage-account-name>.dfs.core.windows.net https://login.microsoftonline.com/<directory-id>/oauth2/token
```



Replace

- `<storage-account-name>` with the name of the ADLS Gen2 storage account.
    arcdstadsl
- `<application-id>` with the Application (client) ID for the Azure Active Directory application.

    Go to Azure portal and select Azure Active Directory from the left navigation.
    Click on App registrations and select your app from the list.
    Click on the Overview tab and look for the Application (client) ID. This is your client id.

- `<secret-scope>` with the name of the client secret scope.
- `<key stored in secret-scope>` with the name of the key containing the client secret.
- `<directory-id>` with the Directory (tenant) ID for the Azure Active Directory application.
    4f8a12af-3d29-4044-9c4f-776617329379


```
spark.hadoop.fs.azure.account.auth.type.arcdstadsl.dfs.core.windows.net OAuth
spark.hadoop.fs.azure.account.oauth.provider.type.arcdstadsl.dfs.core.windows.net org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider
spark.hadoop.fs.azure.account.oauth2.client.id.arcdstadsl.dfs.core.windows.net <application-id>
spark.hadoop.fs.azure.account.oauth2.client.secret.arcdstadsl.dfs.core.windows.net {{secrets/<secret-scope>/<key stored in secret scope>}}
spark.hadoop.fs.azure.account.oauth2.client.endpoint.arcdstadsl.dfs.core.windows.net https://login.microsoftonline.com/4f8a12af-3d29-4044-9c4f-776617329379/oauth2/token
```

directory-id
  click on you name
  hover over `...`
  click on my contact info
  click on Directories + Subscriptions
  Double Click on Directory ID
  hover over `...`
  Click on Copy


# 5. COPY the  SECRET_KEY from azure portal. You will need these keys for establishing a connection from blitzz replicant tool to ADLS. This user will only be used by Blitzz to upload/delete files to ADLS container.


