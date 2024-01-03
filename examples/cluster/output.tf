
output "vpc_name" {
    description = "VPC Name"
    value = module.red5pro.vpc_name
}

output "ssh_key_name" {
  description = "SSH key name"
  value = module.red5pro.ssh_key_name
}

output "ssh_private_key_path" {
  description = "SSH private key path"
  value = module.red5pro.ssh_private_key_path
}

output "stream_manager_ip" {
    description = "Red5 Pro Server IP"
    value = module.red5pro.stream_manager_ip
}

output "red5pro_server_http_url" {
    description = "Red5 Pro Server HTTP URL"
    value = module.red5pro.stream_manager_http_url
}

output "red5pro_server_https_url" {
    description = "Red5 Pro Server HTTPS URL"
    value = module.red5pro.stream_manager_https_url
}

output "database_host" {
  description = "MySQL database host"
  value       = module.red5pro.database_host
}

output "database_user" {
  description = "Database User"
  value = module.red5pro.database_user
}

output "database_port" {
  description = "Database Port"
  value = module.red5pro.database_port
}

output "database_password" {
  sensitive = true
  description = "Database Password"
  value = module.red5pro.database_password
}

output "node_origin_image" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = module.red5pro.node_origin_image
}

output "node_edge_image" {
  description = "Image name of the Red5 Pro Node Edge image"
  value       = module.red5pro.node_edge_image
}

output "node_transcoder_image" {
  description = "Image name of the Red5 Pro Node Transcoder image"
  value       = module.red5pro.node_transcoder_image
}

output "node_relay_image" {
  description = "Image name of the Red5 Pro Node Relay image"
  value       = module.red5pro.node_relay_image
}

output "terraform_service_ip" {
  description = "Terraform Service Host"
  value = module.red5pro.terraform_service_ip
}