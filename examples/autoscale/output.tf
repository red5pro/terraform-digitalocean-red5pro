
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

output "load_balancer_http_url" {
  description = "Red5 Pro Server HTTP URL"
  value       = module.red5pro.load_balancer_http_url
}

output "load_balancer_https_url" {
  description = "Red5 Pro Server HTTPS URL"
  value       = module.red5pro.load_balancer_https_url
}

output "node_image_name" {
  description = "Image name of the Red5 Pro Node Origin image"
  value       = module.red5pro.node_image_name
}
output "rabbitmq_private_ips" {
  description = "RabbitMQ droplets private IPs"
  value       = module.red5pro.rabbitmq_private_ips
}
output "rabbitmq_public_ips" {
  description = "RabbitMQ droplets public IPs"
  value       = module.red5pro.rabbitmq_public_ips
}
output "rabbitmq_user" {
  description = "RabbitMQ user name"
  value       = module.red5pro.rabbitmq_user
}
output "rabbitmq_password" {
  description = "RabbitMQ user password"
  value       = module.red5pro.rabbitmq_password
  sensitive   = true
}
output "stream_manager_intent_user" {
  description = "Stream Manager 2.0 intent API user name"
  value       = module.red5pro.stream_manager_intent_user
}
output "stream_manager_intent_password" {
  description = "Stream Manager 2.0 intent API user password"
  value       = module.red5pro.stream_manager_intent_password
  sensitive   = true
}
