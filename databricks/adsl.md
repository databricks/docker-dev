

Create ADSL

# Step 1: Login to Azure Portal

Login to the portal: portal.azure.com

# Step 2: Search for Storage Accoun

Click `+ Create`
Create legacy storage account type
  Look for Instacen details, `If you need to create a legacy storage account type, please click`

  Subscription: Azure subscription
  Resource group: rslee6392

  Storage account name: arcdstadsl 
  Location: (US) East US
  Performance: Standard
  Account kind: StorageV2 (general purpose v2)
  Replication: Locally-redundant storage (LRS)

Network:
  take default
    Connectivity Method: Public endpoint
    Routing preference: Microsoft network routing (default)
Data protection:
  take default
    nothing is selected
Advanced:
  take default
    Require secure transfer for REST API operations: enabled
    Allow storage account key access: enabled
    Minimum TLS version: verion 1.2
    Infrastructure encryption: disabled
    Allow Blob public access: enabled
    Blob access tier (default): hot

 **  Hierarchical namespace: enabled
    Large file shares: disbaled
    Customer-managed keys support: disabled
Tags:

Review + create
Create



  Review + Create