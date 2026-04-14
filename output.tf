
################################################################################
# OUTPUTS
################################################################################
output "node_image_name" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = try(digitalocean_droplet_snapshot.node-snapshot[0].name, null)
}
output "digital_ocean_project" {
  description = "Digital Ocean project where resources will be created"
  value       = local.digital_ocean_project_name
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

output "stream_manager_ip" {
  description = "Stream Manager IP"
  value       = local.stream_manager_ip
}

output "stream_manager_http_url" {
  description = "Stream Manager HTTP URL"
  value       = local.cluster ? "http://${local.stream_manager_ip}:80" : null
}

output "stream_manager_https_url" {
  description = "Stream Manager HTTPS URL (hostname from stream_manager_public_hostname, not https_ssl_certificate_domain_name — supports wildcard certs)"
  value       = local.cluster ? var.https_ssl_certificate != "none" && var.stream_manager_public_hostname != "" ? "https://${var.stream_manager_public_hostname}:443" : null : null
}

output "standalone_red5pro_server_ip" {
  description = "Signle server red5pro ip"
  value       = local.standalone_server_ip
}

output "standalone_red5pro_server_http_url" {
  description = "Standalone Red5 Pro Server HTTP URL"
  value       = local.standalone ? "http://${local.standalone_server_ip}:5080" : null
}

output "standalone_red5pro_server_https_url" {
  description = "Standalone Red5 Pro Server HTTPS URL"
  value       = local.standalone && var.https_ssl_certificate != "none" ? "https://${var.https_ssl_certificate_domain_name}:443" : null
}

output "load_balancer_ip" {
  description = "Load Balancer IP address"
  value       = local.load_balancer_ip
}

output "load_balancer_https_url" {
  description = "Load Balancer HTTPS URL"
  value       = local.autoscale && var.create_load_balancer_with_ssl ? "https://${local.load_balancer_ip}:443" : null
}

output "load_balancer_http_url" {
  description = "Load Balancer HTTP URL"
  value       = local.autoscale ? "http://${local.load_balancer_ip}:80" : null
}

output "manual_dns_record" {
  description = "DNS hint for TLS: cluster/autoscale uses stream_manager_public_hostname; standalone uses https_ssl_certificate_domain_name"
  value       = local.autoscale ? ( "Please create DNS A record for Stream Manager 2.0: '${var.stream_manager_public_hostname}' -> '${local.stream_manager_ip}'" ) : var.https_ssl_certificate != "none" ? ( local.cluster_or_autoscale ? "Please create DNS A record for Stream Manager 2.0: '${var.stream_manager_public_hostname}' -> '${local.stream_manager_ip}'" : "Please create DNS A record for Standalone Red5 Pro: '${var.https_ssl_certificate_domain_name}' -> '${local.standalone_server_ip}'" ) : ""
}