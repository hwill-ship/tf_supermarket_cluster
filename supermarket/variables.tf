variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-west-2"
}
variable "instance_type" {}
variable "ami" {}
variable "security_groups" {}
variable "key_name" {}

variable "allocated_storage" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "identifier" {}
variable "name" {}
variable "username" {}
variable "password" {}

variable "bucket_name" {}
variable "bucket_acl" {}

variable "cache_cluster_name" {}
variable "cache_cluster_engine" {}
variable "cache_cluster_node_type" {}
variable "cache_cluster_port" {}
variable "cache_cluster_num_nodes" {}
variable "cache_parameter_group_name" {}
