# Bootstrapping Azure

Requirements:
* Packer: https://www.packer.io/downloads.html
* Terraform: `brew install tfswitch`
* Azure elevated rights, to be able to create "Contributor" level service principal.

Outcome:
* This will bake a Windows 10 image for later instantiating into a VM. This will have whatever pre-installed we want, which will shortcut the time take to stand it up.
* This runbook will then stand up the baked image, if you go through with terraform steps.

## Preliminaries

### Setup new automation service principle

* Clear the account data first (in your CLI environment)
    - `az account clear`
* Validate what accounts you can see: 
    - `az account list`
* Login. Note: you'll be directed to the browser to complete the login.
    - `az login`
* You have logged in. Now let us find all the subscriptions to which you have access...
    - az account list
```
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "<redacted>",
    "id": "<redacted>",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Free Trial",
    "state": "Enabled",
    "tenantId": "<redacted>",
    "user": {
      "name": "<redacted>",
      "type": "user"
    }
  }
]
```
* Now, you're logged in as owner, let's setup the new ServicePrincipal:
    - `az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<your subscription id>"`
```
Creating a role assignment under the scope of "/subscriptions/<redacted>"
  Retrying role assignment creation: 1/36
  Retrying role assignment creation: 2/36
{
  "appId": "<redacted>",
  "displayName": "azure-cli-<redacted>",
  "name": "http://azure-cli-<redacted>",
  "password": "<redacted>",
  "tenant": "<redacted>"
}
```
* NOTE: Save the above JSON into a secret area.

* Log out:
    - `az logout`

* Test the new principle:
    - `az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID`

* Do something to validate it works:
    - `az vm list-sizes --location westus`


### Setup the Local Environment
* Create `.env` file with the following details in the Terraform project directory:
```
#!/bin/bash
export TF_VAR_CLIENT_ID="<appId from above>"
export TF_VAR_CLIENT_SECRET="<password from above>"
export TF_VAR_SUBSCRIPTION_ID="<subscription from above>"
export TF_VAR_TENANT_ID="<tenant from above>"
export TF_VAR_LOCATION="<whatever you  want, like eastus>"

#needed for packer.
export TF_VAR_PACKER_RG="<your RG that you will create below>"
export TF_VAR_PACKERNAME="Win10Image"

#needed for Terraform state storage
export TF_VAR_STATE_STORAGE_ACCOUNT="<globally unique thing. `openssl rand -hex 10` is good>"
export TF_VAR_STATE_STORAGE_CONTAINER="tfstate"
export TF_VAR_STATE_KEY="tfstate"

#needed for VM.
export TF_VAR_USERNAME="<the win user>"
#NOTE: should be 8-123 characters long; have uppercase, lowercase, number, or special char
export TF_VAR_PASSWORD="<the win pass>" 
export TF_VAR_WORKSTATION_NAME="workstation-01"
export TF_VAR_WORKSTATION_RG=<the resource group for the workstation>"
# this is the TZ of the created VM.
export TF_VAR_TIMEZONE="Central Standard Time" 

```
* From terminal, source up the envvars:
    - `source .env`
    
* Test the setting of the vars:
    - `echo $TF_VAR_CLIENT_ID`. If you get something, you've got the secrets loaded right. 
    Proceed with your terraform shenanigans.
    
    
### Setup Remote Storage for AMI, and later TF state.

* Create resource group:
    - `az group create --name $TF_VAR_PACKER_RG --location $TF_VAR_LOCATION`


## Bake the AMI with Packer.
### Review / Delete old Packer stuff, if need be
* Remove old VM Image:
    -  `az image list -g $TF_VAR_PACKER_RG --subscription $TF_VAR_SUBSCRIPTION_ID`
    -  `az image delete --ids <the image>` 
    NOTE: This will be in the form of:
    `az image delete --ids /subscriptions/$TF_VAR_SUBSCRIPTION_ID/resourceGroups/$TF_VAR_PACKER_RG/providers/Microsoft.Compute/images/$TF_VAR_PACKERNAME`

### Build new image
* Run `packer build packer/packer.json`
NOTE: This puts an image named $TF_VAR_PACKERNAME in your resource group named $TF_VAR_PACKER_RG
This will take a long time, because of Azure.


## Terraform Work

### Configure remote state backing

* Create Storage Account:
```
az storage account create --name $TF_STATE_STORAGE_ACCOUNT --resource-group $TF_VAR_PACKER_RG --location $TF_VAR_LOCATION --sku Standard_RAGRS  --kind StorageV2
```
    
* Create Container:
```
az storage container create --account-name $TF_STATE_STORAGE_ACCOUNT --name $TF_STATE_STORAGE_CONTAINER
```


### Run  Terraform 


* Init Terraform:
```
terraform init -backend-config "resource_group_name=$TF_VAR_PACKER_RG" -backend-config "storage_account_name=$TF_VAR_STATE_STORAGE_ACCOUNT" -backend-config "container_name=$TF_VAR_STATE_STORAGE_CONTAINER" -backend-config "key=$TF_VAR_STATE_KEY" -backend-config="subscription_id=$TF_VAR_SUBSCRIPTION_ID" -backend-config="client_id=$TF_VAR_CLIENT_ID" -backend-config="client_secret=$TF_VAR_CLIENT_SECRET" -backend-config="tenant_id=$TF_VAR_TENANT_ID"
```
 
* See what will be there:
    - `terraform plan`    
    
* Apply: 
    - `terraform apply` NOTE: you can add `-auto-approve` if you like here.
    
* Your output will show IP, user, pass for the VM. NOTE: the IP may not be fully provisioned yet, so you can get this with:
```
az vm show -d -g $TF_VAR_WORKSTATION_RG -n $TF_VAR_WORKSTATION_NAME --query publicIps -o tsv
```
    
* Login via RDP to the public IP address above.

### Clean everything up:

* Delete infra: `terraform destroy`


### Stopping / Deprovisioning VM:

* Stop VM (note: doesn't stop cost): 
```
az vm stop --resource-group $TF_VAR_WORKSTATION_RG --name $TF_VAR_WORKSTATION_NAME
```

* Deallocate VM (stops costs): 
```
az vm deallocate -g $TF_VAR_WORKSTATION_RG -n $TF_VAR_WORKSTATION_NAME
```