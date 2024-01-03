locals {
  single                               = var.type == "single" ? true : false
  cluster                              = var.type == "cluster" ? true : false
  autoscaling                          = var.type == "autoscaling" ? true : false
  cluster_or_autoscaling               = local.cluster || local.autoscaling ? true : false
  ssh_key                              = var.ssh_key_create ? digitalocean_ssh_key.red5pro_ssh_key[0].fingerprint : data.digitalocean_ssh_key.ssh_key_pair[0].id
  ssh_key_name                         = var.ssh_key_create ? digitalocean_ssh_key.red5pro_ssh_key[0].name : data.digitalocean_ssh_key.ssh_key_pair[0].name
  ssh_private_key                      = var.ssh_key_create ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.ssh_private_key_path)
  ssh_private_key_path                 = var.ssh_key_create ? local_file.red5pro_ssh_key_pem[0].filename : var.ssh_private_key_path
  vpc_id                               = var.vpc_create ? digitalocean_vpc.red5pro_vpc[0].id : data.digitalocean_vpc.selected[0].id
  vpc_name                             = var.vpc_create ? digitalocean_vpc.red5pro_vpc[0].name : data.digitalocean_vpc.selected[0].name
  mysql_local_enable                   = local.autoscaling ? false : var.mysql_database_create ? false : true
  mysql_db_system_create               = local.autoscaling ? true : local.cluster && var.mysql_database_create ? true : local.cluster && var.terraform_service_instance_create ? true : false
  mysql_host                           = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].host : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].host : local.cluster && var.terraform_service_instance_create ? digitalocean_database_cluster.red5pro_mysql[0].host : "localhost"
  mysql_user                           = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].user : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].user : local.cluster && var.terraform_service_instance_create ? digitalocean_database_cluster.red5pro_mysql[0].user : var.mysql_username 
  mysql_password                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].password : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].password : local.cluster && var.terraform_service_instance_create ? digitalocean_database_cluster.red5pro_mysql[0].password : var.mysql_password
  mysql_port                           = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].port : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].port : local.cluster && var.terraform_service_instance_create ? digitalocean_database_cluster.red5pro_mysql[0].port : var.mysql_port
  terraform_service_ip                 = local.autoscaling ? digitalocean_droplet.red5pro_terraform_service[0].ipv4_address : local.cluster && var.terraform_service_instance_create ? digitalocean_droplet.red5pro_terraform_service[0].ipv4_address : "localhost"
  terraform_service_local_enable       = local.autoscaling ? false : local.cluster && var.terraform_service_instance_create ? false : true
  dedicated_terraform_service_create   = local.autoscaling ? true : local.cluster && var.terraform_service_instance_create ? true : false
  stream_manager_ip                    = local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].ip : local.cluster ? digitalocean_droplet.red5pro_sm[0].ipv4_address : null
  single_server_ip                     = local.single ? digitalocean_droplet.red5pro_single[0].ipv4_address : null
  lb_certificate_name                  = local.autoscaling && var.lb_ssl_create ? digitalocean_certificate.new_lb_cert[0].name : null
  lb_ip                                = local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].ip : null
  stream_managers_amount               = local.autoscaling ? var.stream_managers_amount : local.cluster ? 1 : 0
  stream_managers_id                   = [ for red5pro_sm in digitalocean_droplet.red5pro_sm : red5pro_sm.id ]
  stream_managers_urn                  = [ for red5pro_sm in digitalocean_droplet.red5pro_sm : red5pro_sm.urn ]
  project_resources                    = concat(
    compact([ local.single ? digitalocean_droplet.red5pro_single[0].urn : "" ]),
    compact([ local.cluster ? digitalocean_droplet.red5pro_sm[0].urn : "" ]),
    compact([ local.mysql_db_system_create ? digitalocean_database_cluster.red5pro_mysql[0].urn : "" ]),
    compact([ local.dedicated_terraform_service_create ? digitalocean_droplet.red5pro_terraform_service[0].urn : "" ]),
    compact([ var.origin_image_create ? digitalocean_droplet.red5pro_origin_node[0].urn : "" ]),
    compact([ var.edge_image_create ? digitalocean_droplet.red5pro_edge_node[0].urn : "" ]),
    compact([ var.transcoder_image_create ? digitalocean_droplet.red5pro_transcoder_node[0].urn : "" ]),
    compact([ var.relay_image_create ? digitalocean_droplet.red5pro_relay_node[0].urn : "" ]),
    compact([ local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].urn : "" ]),
    compact(local.stream_managers_urn)
  )
}
