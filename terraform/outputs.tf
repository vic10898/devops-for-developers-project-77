output "load_balancer_ip" {
  value       = yandex_alb_load_balancer.web_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
  description = "Public IP address of the Application Load Balancer"
}

output "web_server_ips" {
  value       = yandex_compute_instance.web[*].network_interface[0].nat_ip_address
  description = "Public IP addresses of the web servers"
}

output "database_host" {
  value       = [for h in yandex_mdb_postgresql_cluster.db_cluster.host : h.fqdn][0]
  description = "Internal FQDN of the PostgreSQL database host"
}
