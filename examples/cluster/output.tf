
output "vpc_name" {
  description = "VPC Name"
  value       = module.red5pro.vpc_name
}

output "ssh_key_name" {
  description = "SSH key name"
  value       = module.red5pro.ssh_key_name
}

output "ssh_private_key_path" {
  description = "SSH private key path"
  value       = module.red5pro.ssh_private_key_path
}

output "stream_manager_ip" {
  description = "Red5 Pro Server IP"
  value       = module.red5pro.stream_manager_ip
}

output "red5pro_server_http_url" {
  description = "Red5 Pro Server HTTP URL"
  value       = module.red5pro.stream_manager_http_url
}

output "red5pro_server_https_url" {
  description = "Red5 Pro Server HTTPS URL"
  value       = module.red5pro.stream_manager_https_url
}

output "node_image_name" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = module.red5pro.node_image_name
}
