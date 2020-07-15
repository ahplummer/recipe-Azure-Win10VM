#This will be captured for later viewing/usage for downstream pipelines, etc,
#usually via `tf output ____` or just plain `tf output` for all.


//output "my_var" {
//  description "My Totally Interesting description"
//  value = the_terraform_declared_thing
//}

output "external_ip" {
  description = "This is your public IP with 3389 open to the internet"
  value = azurerm_public_ip.workstation_public_ip.ip_address
}
output "vm_user" {
  description = "This is your VM user, keep it safe."
  value = var.USERNAME
}
output "vm_password" {
  description = "This is your VM password, keep it safe."
  value = var.PASSWORD
}

