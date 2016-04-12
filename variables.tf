variable "aws_iam_username" {}
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable "instance_type" {}
variable "ami" {}
variable "private_ssh_key_path" {}
variable "key_name" {}
variable "chef-server-user" {}
variable "chef-server-user-full-name" {}
variable "chef-server-user-email" {}
variable "chef-server-user-password" {}
variable "chef-server-org-name" {}
variable "chef-server-org-full-name" {}

variable "db_allocated_storage" {}
variable "db_engine" {}
variable "db_engine_version" {}
variable "db_instance_class" {}
variable "db_identifier" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}

variable "bucket_name" {}
variable "bucket_acl" {}

variable "cache_cluster_name" {}
variable "cache_cluster_engine" {}
variable "cache_cluster_node_type" {}
variable "cache_cluster_port" {}
variable "cache_cluster_num_nodes" {}
variable "cache_parameter_group_name" {}

variable "fieri_key" {}
