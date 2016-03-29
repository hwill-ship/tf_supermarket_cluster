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
  allocated_storage = "${var.db_allocated_storage}"
  engine = "${var.db_engine}"
  engine_version = "${var.db_engine_version}"
  instance_class = "${var.db_instance_class}"
  identifier = "${var.db_identifier}"
  name = "${var.db_name}"
  username = "${var.db_username}"
  password = "${var.db_password}"  
}

resource "aws_s3_bucket" "supermarket-bucket" {
  bucket = "${var.bucket_name}"
  acl = "${var.bucket_acl}"
  policy = <<POLICY
{
"Id": "Policy1459815636248",
"Version": "2012-10-17",
"Statement": [
{
	"Sid": "Stmt1459815634494",
	"Action": "s3:*",
	"Effect": "Allow",
	"Resource": "arn:aws:s3:::${var.bucket_name}",
	"Principal": {
			"AWS": [
				"arn:aws:iam::142602949470:user/${var.aws_iam_username}"
			]
		}
		}
	]
}
POLICY
}

resource "aws_elasticache_cluster" "supermarket_cluster" {
  cluster_id = "${var.cache_cluster_name}"
  engine = "${var.cache_cluster_engine}"
  node_type = "${var.cache_cluster_node_type}"
  port = "${var.cache_cluster_port}"
  num_cache_nodes = "${var.cache_cluster_num_nodes}"
  parameter_group_name = "${var.cache_parameter_group_name}"
}
