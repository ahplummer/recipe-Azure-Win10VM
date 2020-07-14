# This is the specifics of the backent (s3 or Azure storage particulars)
# this ideally is envvars passed in at the `tf init` state.

//provider "azurerm" {
//  version = "2.2.0"
//  subscription_id = var.SUBSCRIPTION_ID
//  client_id = var.CLIENT_ID
//  client_secret = var.CLIENT_SECRET
//  tenant_id = var.TENANT_ID
//  features {}
//}