variable "admin_ssh_ips" {
  description = "IP addresses (CIDR) allowed to SSH into the VM. Set the real values in terraform.tfvars, which is git-ignored."
  type        = list(string)
}
