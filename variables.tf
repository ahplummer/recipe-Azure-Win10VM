# This is really only to declare variables, both envvars, and local that you'll
# define in your variables.tf file.

#ENVVARS in the form of TF_VAR_BLAH
#variable "BLAH" {}
variable "SUBSCRIPTION_ID" {}
variable "CLIENT_ID" {}
variable "CLIENT_SECRET" {}
variable "TENANT_ID" {}
variable "USERNAME" {}
variable "PASSWORD" {}
variable "PACKERNAME" {}
variable "WORKSTATION_RG" {}
variable "LOCATION" {}
variable "TIMEZONE" {}
variable "PACKER_RG" {}
variable "WORKSTATION_NAME" {}

#locals here...usually defined over in terraform.tfvars
#variable localVariable {}
variable "resource_prefix" {}
variable "workstation_address_space" {}
variable "workstation_address_prefix" {}
