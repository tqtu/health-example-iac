variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "env" {}
variable "common_tags" { type = map(string) }
