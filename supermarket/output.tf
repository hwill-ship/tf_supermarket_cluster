output "public_ip" {
  value = "${aws_instance.supermarket-server.public_ip}"
}

output "public_dns" {
  value = "${aws_instance.supermarket-server.public_dns}"
}

output "database_host" {
  value = "${aws_db_instance.supermarket-db.endpoint}"
}

output "database_port" {
  value = "${aws_db_instance.supermarket-db.port}"
}

output "elasticache_url" {
  value = "${aws_elasticache_cluster.supermarket_cluster.cache_nodes.0.address}"
}
