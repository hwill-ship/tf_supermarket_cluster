provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}

resource "aws_instance" "supermarket-server" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  tags {
    Name = "supermarket-server"
  }
  security_groups = ["${split(",", var.security_groups)}"]
  key_name = "${var.key_name}"
}

resource "aws_db_instance" "supermarket-db" {
  allocated_storage = "${var.allocated_storage}"
  engine = "${var.engine}"
  engine_version = "${var.engine_version}"
  instance_class = "${var.instance_class}"
  identifier = "${var.identifier}"
  name = "${var.name}"
  username = "${var.name}"
  password = "${var.password}"  
}

resource "aws_s3_bucket" "supermarket-bucket" {
  bucket = "${var.bucket_name}"
  acl = "${var.bucket_acl}"
  tags {
    Name = "Supermarket Artifact Storage"
  }
}

resource "aws_elasticache_cluster" "supermarket_cluster" {
  cluster_id = "${var.cache_cluster_name}"
  engine = "${var.cache_cluster_engine}"
  node_type = "${var.cache_cluster_node_type}"
  port = "${var.cache_cluster_port}"
  num_cache_nodes = "${var.cache_cluster_num_nodes}"
  parameter_group_name = "${var.cache_parameter_group_name}"
}
