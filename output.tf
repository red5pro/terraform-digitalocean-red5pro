
################################################################################
# OUTPUTS
################################################################################
output "node_origin_image" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = try(digitalocean_droplet_snapshot.origin-snapshot[0].name, null)
}

output "node_edge_image" {
  description = "Image name of the Red5 Pro Node Edge image"
  value       = try(digitalocean_droplet_snapshot.edge-snapshot[0].name, null)
}

output "node_transcoder_image" {
  description = "Image name of the Red5 Pro Node Transcoder image"
  value       = try(digitalocean_droplet_snapshot.transcoder-snapshot[0].name, null)
}

output "node_relay_image" {
  description = "Image name of the Red5 Pro Node Relay image"
  value       = try(digitalocean_droplet_snapshot.relay-snapshot[0].name, null)
}

output "digital_ocean_project" {
  description = "Digital Ocean project where resources will be created"
  value = var.digital_ocean_project ? var.project_name : null
}

output "ssh_key_name" {
  description = "SSH key name"
  value       = local.ssh_key_name
}

output "vpc_name" {
  description = "VPC Name"
  value       = local.vpc_name
}

output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = local.ssh_private_key_path
}

output "database_host" {
  description = "MySQL database host"
  value       = local.mysql_host
}

output "database_user" {
  description = "Database User"
  value = local.mysql_user
}

output "database_port" {
  description = "Database Port"
  value = local.mysql_port
}

output "database_password" {
  sensitive = true
  description = "Database Password"
  value = local.mysql_password
}

output "stream_manager_ip" {
  description = "Stream Manager IP"
  value = local.stream_manager_ip
}

output "stream_manager_http_url" {
  description = "Stream Manager HTTP URL"
  value       = local.cluster || local.autoscaling ? "http://${local.stream_manager_ip}:5080" : null
}

output "stream_manager_https_url" {
  description = "Stream Manager HTTPS URL"
  value       = local.cluster || local.autoscaling ? var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null : null
}

output "single_red5pro_server_ip" {
  description = "Signle server red5pro ip"
  value = local.single_server_ip
}

output "single_red5pro_server_http_url" {
  description = "Single Red5 Pro Server HTTP URL"
  value = local.single ? "http://${local.single_server_ip}:5080" : null
}

output "single_red5pro_server_https_url" {
  description = "Single Red5 Pro Server HTTPS URL"
  value = local.single && var.https_letsencrypt_enable ? "https://${var.https_letsencrypt_certificate_domain_name}:443" : null
}

output "load_balancer_ip" {
  description = "Load Balancer IP address"
  value = local.lb_ip
}

output "load_balancer_https_url" {
  description = "Load Balancer HTTPS URL"
  value = local.autoscaling ? "https://${local.lb_ip}:443" : null
}