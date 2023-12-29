locals {
  single                           = var.type == "single" ? true : false
  cluster                          = var.type == "cluster" ? true : false
  autoscaling                      = var.type == "autoscaling" ? true : false
  ubuntu_image_version             = var.ubuntu_version == "20.04" ? "ubuntu-20-04-x64" : "ubuntu-22-04-x64"
  ssh_key                          = var.ssh_key_create ? digitalocean_ssh_key.red5pro_ssh_key[0].fingerprint : data.digitalocean_ssh_key.ssh_key_pair[0].id
  ssh_key_name                     = var.ssh_key_create ? digitalocean_ssh_key.red5pro_ssh_key[0].name : data.digitalocean_ssh_key.ssh_key_pair[0].name
  ssh_private_key                  = var.ssh_key_create ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.ssh_private_key_path)
  ssh_private_key_path             = var.ssh_key_create ? local_file.red5pro_ssh_key_pem[0].filename : var.ssh_private_key_path
  vpc_id                           = var.vpc_create ? digitalocean_vpc.red5pro_vpc[0].id : data.digitalocean_vpc.selected[0].id
  vpc_name                         = var.vpc_create ? digitalocean_vpc.red5pro_vpc[0].name : data.digitalocean_vpc.selected[0].name
  mysql_local_enable               = local.autoscaling ? false : var.mysql_database_create ? false : true
  mysql_db_system_create           = local.autoscaling ? true : local.cluster && var.mysql_database_create ? true : local.cluster && var.dedicated_terraform_service_host_create ? true : false
  mysql_host                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].host : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].host : local.cluster && var.dedicated_terraform_service_host_create ? digitalocean_database_cluster.red5pro_mysql[0].host : "localhost"
  mysql_user                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].user : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].user : local.cluster && var.dedicated_terraform_service_host_create ? digitalocean_database_cluster.red5pro_mysql[0].user : var.mysql_username 
  mysql_password                   = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].password : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].password : local.cluster && var.dedicated_terraform_service_host_create ? digitalocean_database_cluster.red5pro_mysql[0].password : var.mysql_password
  mysql_port                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].port : local.cluster && var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].port : local.cluster && var.dedicated_terraform_service_host_create ? digitalocean_database_cluster.red5pro_mysql[0].port : var.mysql_port
  terraform_host                   = local.autoscaling ? digitalocean_droplet.red5pro_terraform_service[0].ipv4_address : local.cluster && var.dedicated_terraform_service_host_create ? digitalocean_droplet.red5pro_terraform_service[0].ipv4_address : "localhost"
  terraform_host_local_enable      = local.autoscaling ? false : local.cluster && var.dedicated_terraform_service_host_create ? false : true
  dedicated_terraform_host_create  = local.autoscaling ? true : local.cluster && var.dedicated_terraform_service_host_create ? true : false
  stream_manager_ip                = local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].ip : local.cluster ? digitalocean_droplet.red5pro_sm[0].ipv4_address : null
  single_server_ip                 = local.single ? digitalocean_droplet.red5pro_single[0].ipv4_address : null
  lb_certificate_name              = local.autoscaling && var.lb_ssl_create ? digitalocean_certificate.new_lb_cert[0].name : null
  lb_ip                            = local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].ip : null
  stream_manager_node_ids          = [ for autoscale_sm_droplet in digitalocean_droplet.red5pro_autoscale_sm : autoscale_sm_droplet.id ]
  autoscale_sm_droplet_urn         = [ for autoscale_sm_urn in digitalocean_droplet.red5pro_autoscale_sm : autoscale_sm_urn.urn ]
  project_resources                = concat(
    compact([ local.single ? digitalocean_droplet.red5pro_single[0].urn : "" ]),
    compact([ local.cluster ? digitalocean_droplet.red5pro_sm[0].urn : "" ]),
    compact([ local.mysql_db_system_create ? digitalocean_database_cluster.red5pro_mysql[0].urn : "" ]),
    compact([ local.dedicated_terraform_host_create ? digitalocean_droplet.red5pro_terraform_service[0].urn : "" ]),
    compact([ var.origin_image_create ? digitalocean_droplet.red5pro_origin_node[0].urn : "" ]),
    compact([ var.edge_image_create ? digitalocean_droplet.red5pro_edge_node[0].urn : "" ]),
    compact([ var.transcoder_image_create ? digitalocean_droplet.red5pro_transcoder_node[0].urn : "" ]),
    compact([ var.relay_image_create ? digitalocean_droplet.red5pro_relay_node[0].urn : "" ]),
    compact([ local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].urn : "" ]),
    compact(local.autoscale_sm_droplet_urn)
  )
}

################################################################################
# PROJECT SETUP IN DIGITAL OCEAN
################################################################################

data "digitalocean_project" "do_project" {
  count = var.project_create ? 0 : 1
  name  = var.project_name
}

resource "digitalocean_project_resources" "do_project" {
  count       = var.project_create ? 0 : 1
  project     = data.digitalocean_project.do_project[0].id
  resources   = local.project_resources
}

resource "digitalocean_project" "do_project" {
  count       = var.project_create ? 1 : 0
  name        = var.project_name
  purpose     = "${var.name}-Red5Pro Deployments"
  environment = "Production"
  resources = local.project_resources
}

################################################################################
# SSH_KEY
################################################################################
# SSH key pair generation
resource "tls_private_key" "red5pro_ssh_key" {
  count     = var.ssh_key_create ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Import SSH key pair to DO
resource "digitalocean_ssh_key" "red5pro_ssh_key" {
  count      = var.ssh_key_create ? 1 : 0
  name       = var.ssh_key_name
  public_key = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Save SSH key pair files to local folder
resource "local_file" "red5pro_ssh_key_pem" {
  count           = var.ssh_key_create ? 1 : 0
  filename        = "./${var.ssh_key_name}.pem"
  content         = tls_private_key.red5pro_ssh_key[0].private_key_pem
  file_permission = "0400"
}

resource "local_file" "red5pro_ssh_key_pub" {
  count    = var.ssh_key_create ? 1 : 0
  filename = "./${var.ssh_key_name}.pub"
  content  = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Check current SSH key pair on the DO
data "digitalocean_ssh_key" "ssh_key_pair" {
  count = var.ssh_key_create ? 0 : 1
  name  = var.ssh_key_name
  lifecycle {
    postcondition {
      condition =    self.name != null && self.name != ""
      error_message = "ERROR! No SSH keys found with name ${var.ssh_key_name} in Digital Ocean Account."
    }
  }
}

################################################################################
# VPC - Create new/existing (VPC)
################################################################################
resource "digitalocean_vpc" "red5pro_vpc" {
  count    = var.vpc_create ? 1 : 0
  ip_range = var.vpc_cidr_block
  region   = var.digital_ocean_region
  name     = "${var.name}-vpc"
}

# VPC - Use existing
data "digitalocean_vpc" "selected" {
  count = var.vpc_create ? 0 : 1
  name  = var.vpc_name_existing
  lifecycle {
    postcondition {
      condition     = self.name != null && self.name != ""
      error_message = "ERROR! VPC name ${var.vpc_name_existing} does not exist in the Digital Ocean Account"
    }
  }
}

################################################################################
# Red5 Pro Single server (DO Droplet)
################################################################################
resource "digitalocean_droplet" "red5pro_single" {
  count    = local.single ? 1 : 0
  name     = "${var.name}-red5-single"
  region   = var.digital_ocean_region
  size     = var.single_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_single[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_API_KEY='${var.stream_manager_api_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY='${var.red5pro_cloudstorage_digitalocean_spaces_access_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY='${var.red5pro_cloudstorage_digitalocean_spaces_secret_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME='${var.red5pro_cloudstorage_digitalocean_spaces_name}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION='${var.red5pro_cloudstorage_digitalocean_spaces_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.red5pro_cloudstorage_postprocessor_enable}'",
      "export SSL_ENABLE='${var.https_letsencrypt_enable}'",
      "export SSL_DOMAIN='${var.https_letsencrypt_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_letsencrypt_certificate_email}'",
      "export SSL_PASSWORD='${var.https_letsencrypt_certificate_password}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "nohup sudo -E /home/red5pro-installer/r5p_ssl_check_install.sh >> /home/red5pro-installer/r5p_ssl_check_install.log &",
      "sleep 2"

    ]
    connection {
      host        = digitalocean_droplet.red5pro_single[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}


################################################################################
# Firewall for Single Red5Pro server (DO Droplet)
################################################################################
# Firewall for single red5pro droplet
resource "digitalocean_firewall" "red5pro_single_fw" {
  count       = local.single ? 1 : 0
  name        = "${var.name}-single-fw"
  droplet_ids = [digitalocean_droplet.red5pro_single[0].id]

  dynamic "inbound_rule" {
    for_each = var.inbound_rules
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  dynamic "outbound_rule" {
    for_each = var.outbound_rules
    content {
      protocol              = outbound_rule.value.protocol
      port_range            = outbound_rule.value.port_range
      destination_addresses = outbound_rule.value.destination_addresses
    }
  }
}

# Firewall for stream Manger red5pro droplet
resource "digitalocean_firewall" "red5pro_sm_fw" {
  count       = local.cluster || local.autoscaling ? 1 : 0
  name        = "${var.name}-stream-manager-fw"
  droplet_ids = local.autoscaling ? local.stream_manager_node_ids : [digitalocean_droplet.red5pro_sm[0].id]

  dynamic "inbound_rule" {
    for_each = var.firewall_stream_manager_inbound
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  dynamic "outbound_rule" {
    for_each = var.firewall_stream_manager_outbound
    content {
      protocol              = outbound_rule.value.protocol
      port_range            = outbound_rule.value.port_range
      destination_addresses = outbound_rule.value.destination_addresses
    }
  }
}

################################################################################
# Stream manager - (DO droplet)
################################################################################
# Stream Manager droplet
resource "digitalocean_droplet" "red5pro_sm" {
  count    = local.cluster || local.autoscaling ? 1 : 0
  name     = "${var.name}-red5-sm"
  region   = var.digital_ocean_region
  size     = var.stream_manager_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_sm[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "file" {
    source      = var.path_to_terraform_cloud_controller
    destination = "/home/red5pro-installer/${basename(var.path_to_terraform_cloud_controller)}"
  }

  provisioner "file" {
    source      = var.path_to_terraform_service_build
    destination = "/home/red5pro-installer/${basename(var.path_to_terraform_service_build)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      # Stream Manager
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_API_KEY='${var.stream_manager_api_key}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_PREFIX_NAME='${var.name}-node'",
      "export DB_LOCAL_ENABLE='${local.mysql_local_enable}'",
      "export DB_HOST='${local.mysql_host}'",
      "export DB_PORT='${local.mysql_port}'",
      "export DB_USER='${local.mysql_user}'",
      "export DB_PASSWORD='${nonsensitive(local.mysql_password)}'",
      "export SSL_ENABLE='${var.https_letsencrypt_enable}'",
      "export SSL_DOMAIN='${var.https_letsencrypt_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_letsencrypt_certificate_email}'",
      "export SSL_PASSWORD='${var.https_letsencrypt_certificate_password}'",
      # For Terraform Service
      "export TF_SVC_ENABLE='${local.terraform_host_local_enable}'",
      "export TERRA_HOST='${local.terraform_host}'",
      "export TERRA_API_TOKEN='${var.terraform_service_api_token}'",
      "export TERRA_PARALLELISM='${var.terraform_service_parallelism}'",
      "export DO_API_TOKEN='${var.digital_ocean_token}'",
      "export SSH_KEY_NAME='${local.ssh_key_name}'",
      ###################################      
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_install_mysql_local.sh",
      "sudo -E /home/red5pro-installer/r5p_install_terraform_svc.sh",
      "sudo -E /home/red5pro-installer/r5p_config_stream_manager.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "nohup sudo -E /home/red5pro-installer/r5p_ssl_check_install.sh >> /home/red5pro-installer/r5p_ssl_check_install.log &",
      "sleep 2"

    ]
    connection {
      host        = digitalocean_droplet.red5pro_sm[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

# Autoscale Stream Manager Droplet 
resource "digitalocean_droplet" "red5pro_autoscale_sm" {
  count    = local.autoscaling ? var.autoscale_stream_manager_count : 0
  name     = "${var.name}-autoscale-stream-manager-${count.index}"
  region   = var.digital_ocean_region
  size     = var.stream_manager_droplet_size
  image    = digitalocean_droplet_snapshot.sm-snapshot[0].id
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LB_SM_IP='${self.ipv4_address}'", 
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_config_lb_stream_manager.sh",
      "sudo systemctl daemon-reload && sudo systemctl restart red5pro",
      "sleep 2"
    ]
    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
  depends_on = [ digitalocean_droplet.red5pro_sm ]
}

################################################################################
# Stream manager - Database MySQL Configuration
################################################################################
# Stream Manager Database Digital Ocean
resource "digitalocean_database_cluster" "red5pro_mysql" {
  count      = local.mysql_db_system_create ? 1 : 0
  name       = "${var.name}-mysql-sm-db"
  region     = var.digital_ocean_region
  version    = "8"
  size       = var.mysql_database_size
  node_count = 1
  engine     = "mysql"
  private_network_uuid = local.vpc_id
}

# Allowing stream manager and terraform service droplet to access the MySQL Database
resource "digitalocean_database_firewall" "database_fw" {
  count      = local.mysql_db_system_create ? 1 : 0
  cluster_id = digitalocean_database_cluster.red5pro_mysql[0].id

  dynamic "rule" {
    for_each = local.autoscaling ? toset(digitalocean_droplet.red5pro_autoscale_sm[*].id) : toset(digitalocean_droplet.red5pro_sm[*].id)
    content {
      type  = "droplet"
      value = rule.key
    }
  }
  rule {
    type     = "droplet"
    value    = var.dedicated_terraform_service_host_create ? digitalocean_droplet.red5pro_terraform_service[0].id : digitalocean_droplet.red5pro_sm[0].id
  }
}

################################################################################
# DO droplet Terraform Service
################################################################################
resource "digitalocean_droplet" "red5pro_terraform_service" {
  count    = local.dedicated_terraform_host_create ? 1 : 0
  name     = "${var.name}-red5-terraform-service"
  region   = var.digital_ocean_region
  size     = var.terraform_service_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_terraform_service[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_terraform_service_build
    destination = "/home/red5pro-installer/${basename(var.path_to_terraform_service_build)}"
  }

  provisioner "file" {
    source      = var.path_to_terraform_cloud_controller
    destination = "/home/red5pro-installer/${basename(var.path_to_terraform_cloud_controller)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo cloud-init status --wait",
      "export DO_API_TOKEN='${var.digital_ocean_token}'",
      "export SSH_KEY_NAME='${local.ssh_key_name}'",
      "export TF_SVC_ENABLE=true",
      "export TERRA_HOST='${self.ipv4_address}'",
      "export TERRA_API_TOKEN='${var.terraform_service_api_token}'",
      "export TERRA_PARALLELISM='${var.terraform_service_parallelism}'",
      "export DB_HOST='${local.mysql_host}'",
      "export DB_PORT='${local.mysql_port}'",
      "export DB_USER='${local.mysql_user}'",
      "export DB_PASSWORD='${nonsensitive(local.mysql_password)}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_terraform_svc.sh",
      "sleep 2"
    ]
    connection {
      host        = digitalocean_droplet.red5pro_terraform_service[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

# Firewall for Terraform Service droplet
resource "digitalocean_firewall" "red5pro_terraform_service_fw" {
  count       = local.dedicated_terraform_host_create ? 1 : 0
  name        = "${var.name}-terraform-service-fw"
  droplet_ids = [digitalocean_droplet.red5pro_terraform_service[0].id]

  dynamic "inbound_rule" {
    for_each = var.firewall_terraform_service_inbound
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  dynamic "outbound_rule" {
    for_each = var.firewall_terraform_service_outbound
    content {
      protocol              = outbound_rule.value.protocol
      port_range            = outbound_rule.value.port_range
      destination_addresses = outbound_rule.value.destination_addresses
    }
  }
}

################################################################################
# Load Balancer for Red5Pro Stream Manager
################################################################################
resource "digitalocean_loadbalancer" "red5pro_lb" {
  count  = local.autoscaling ? 1 : 0
  name   = "${var.name}-red5pro-lb"
  region = var.digital_ocean_region
  size   = var.lb_size

  forwarding_rule {
    entry_port     = var.lb_ssl_create ? 443 : 5080
    entry_protocol = var.lb_ssl_create ? "https" : "http"

    target_port     = var.https_letsencrypt_enable ? 443 : 5080
    target_protocol = var.https_letsencrypt_enable ? "https" : "http"

    certificate_name = local.lb_certificate_name
  }
  forwarding_rule {
    entry_port     = 5080
    entry_protocol = "http"

    target_port     = var.https_letsencrypt_enable ? 443 : 5080
    target_protocol = var.https_letsencrypt_enable ? "https" : "http"
  }

  healthcheck {
    port     = var.https_letsencrypt_enable ? 443 : 5080
    protocol = var.https_letsencrypt_enable ? "https" : "http"
    path = "/"
  }

  sticky_sessions {
    type = "cookies"
    cookie_name = "${var.name}-lb-cookie"
    cookie_ttl_seconds = 300
  }

  vpc_uuid = local.vpc_id
  droplet_ids = local.stream_manager_node_ids
  depends_on = [ digitalocean_droplet.red5pro_autoscale_sm ]
}

# Load Balancer Certificate 
resource "digitalocean_certificate" "new_lb_cert" {
  count            = var.lb_ssl_create && local.autoscaling ? 1 : 0
  name             = "${var.name}-lb-ssl-cert"
  type             = "custom"

  private_key       = file(var.cert_private_key)
  leaf_certificate  = file(var.leaf_public_cert)
  certificate_chain = file(var.cert_fullchain)

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# Red5 Pro Autoscaling Nodes - Origin/Edge/Transcoders/Relay (DO Droplet)
################################################################################
# Origin Node droplet for DO Custom Image
resource "digitalocean_droplet" "red5pro_origin_node" {
  count    = local.cluster || local.autoscaling && var.origin_image_create ? 1 : 0
  name     = "${var.name}-node-origin-image"
  region   = var.digital_ocean_region
  size     = var.origin_image_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_origin_node[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.origin_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.origin_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.origin_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.origin_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.origin_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.origin_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.origin_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.origin_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.origin_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.origin_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.origin_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.origin_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY='${var.origin_red5pro_cloudstorage_digitalocean_spaces_access_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY='${var.origin_red5pro_cloudstorage_digitalocean_spaces_secret_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME='${var.origin_red5pro_cloudstorage_digitalocean_spaces_name}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION='${var.origin_red5pro_cloudstorage_digitalocean_spaces_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.origin_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = digitalocean_droplet.red5pro_origin_node[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

# Edge Node droplet for DO Custom Image
resource "digitalocean_droplet" "red5pro_edge_node" {
  count    = local.cluster || local.autoscaling && var.edge_image_create ? 1 : 0
  name     = "${var.name}-node-edge-image"
  region   = var.digital_ocean_region
  size     = var.edge_image_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_edge_node[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.edge_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.edge_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.edge_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.edge_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.edge_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.edge_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.edge_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.edge_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.edge_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.edge_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.edge_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.edge_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY='${var.edge_red5pro_cloudstorage_digitalocean_spaces_access_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY='${var.edge_red5pro_cloudstorage_digitalocean_spaces_secret_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME='${var.edge_red5pro_cloudstorage_digitalocean_spaces_name}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION='${var.edge_red5pro_cloudstorage_digitalocean_spaces_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.edge_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = digitalocean_droplet.red5pro_edge_node[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

# Transcoder Node droplet for DO Custom Image
resource "digitalocean_droplet" "red5pro_transcoder_node" {
  count    = local.cluster || local.autoscaling && var.transcoder_image_create ? 1 : 0
  name     = "${var.name}-node-transcoder-image"
  region   = var.digital_ocean_region
  size     = var.transcoder_image_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_transcoder_node[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.transcoder_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.transcoder_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.transcoder_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.transcoder_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.transcoder_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.transcoder_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.transcoder_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.transcoder_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.transcoder_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.transcoder_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.transcoder_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.transcoder_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY='${var.transcoder_red5pro_cloudstorage_digitalocean_spaces_access_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY='${var.transcoder_red5pro_cloudstorage_digitalocean_spaces_secret_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME='${var.transcoder_red5pro_cloudstorage_digitalocean_spaces_name}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION='${var.transcoder_red5pro_cloudstorage_digitalocean_spaces_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.transcoder_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = digitalocean_droplet.red5pro_transcoder_node[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

# Relay Node droplet for DO Custom Image
resource "digitalocean_droplet" "red5pro_relay_node" {
  count    = local.cluster || local.autoscaling && var.relay_image_create ? 1 : 0
  name     = "${var.name}-node-relay-image"
  region   = var.digital_ocean_region
  size     = var.relay_image_droplet_size
  image    = local.ubuntu_image_version
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_id

  connection {
    host        = digitalocean_droplet.red5pro_relay_node[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "file" {
    source      = var.path_to_red5pro_build
    destination = "/home/red5pro-installer/${basename(var.path_to_red5pro_build)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo iptables -F",
      "export LICENSE_KEY='${var.red5pro_license_key}'",
      "export SM_IP='${local.stream_manager_ip}'",
      "export NODE_CLUSTER_KEY='${var.red5pro_cluster_key}'",
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.relay_image_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.relay_image_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.relay_image_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.relay_image_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.relay_image_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.relay_image_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.relay_image_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.relay_image_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.relay_image_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.relay_image_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.relay_image_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.relay_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY='${var.relay_red5pro_cloudstorage_digitalocean_spaces_access_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY='${var.relay_red5pro_cloudstorage_digitalocean_spaces_secret_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME='${var.relay_red5pro_cloudstorage_digitalocean_spaces_name}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION='${var.relay_red5pro_cloudstorage_digitalocean_spaces_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.relay_red5pro_cloudstorage_postprocessor_enable}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sleep 2"

    ]
    connection {
      host        = digitalocean_droplet.red5pro_relay_node[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

####################################################################################################
# Red5 Pro Autoscaling Nodes create images - Origin/Edge/Transcoders/Relay (DO Custom Images)
####################################################################################################
# Stream Manager Image Autoscale
resource "digitalocean_droplet_snapshot" "sm-snapshot" {
  count          = local.autoscaling ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_sm[0].id
  name           = "${var.name}-autoscale-stream-manager-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_sm]
}
# Origin node - Create image
resource "digitalocean_droplet_snapshot" "origin-snapshot" {
  count          = local.cluster || local.autoscaling && var.origin_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_origin_node[0].id
  name           = "${var.name}-node-origin-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_origin_node]
}

# Edge node - Create image
resource "digitalocean_droplet_snapshot" "edge-snapshot" {
  count          = local.cluster || local.autoscaling && var.edge_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_edge_node[0].id
  name           = "${var.name}-node-edge-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_edge_node]
}

# Transcode node - Create image
resource "digitalocean_droplet_snapshot" "transcoder-snapshot" {
  count          = local.cluster || local.autoscaling && var.transcoder_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_transcoder_node[0].id
  name           = "${var.name}-node-transcoder-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_transcoder_node]
}

# Relay node - Create image
resource "digitalocean_droplet_snapshot" "relay-snapshot" {
  count          = local.cluster || local.autoscaling && var.relay_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_relay_node[0].id
  name           = "${var.name}-node-relay-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_relay_node]
}

################################################################################
# Stop droplet which used for creating DO custom images (DO CLI)
################################################################################
# Stop Stream Manager droplet using DO CLI
resource "null_resource" "stop_stream_manager" {
  count = local.autoscaling ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_sm[0].id} -f --access-token ${var.digital_ocean_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.sm-snapshot]
}
# Stop Origin Node droplet using DO CLI
resource "null_resource" "stop_node_origin" {
  count = local.cluster || local.autoscaling && var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_origin_node[0].id} -f --access-token ${var.digital_ocean_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.origin-snapshot]
}
# Stop Edge Node droplet using DO CLI
resource "null_resource" "stop_node_edge" {
  count = local.cluster || local.autoscaling && var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_edge_node[0].id} -f --access-token ${var.digital_ocean_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.edge-snapshot]
}
# Stop Transcoder Node droplet using DO CLI
resource "null_resource" "stop_node_transcoder" {
  count = local.cluster || local.autoscaling && var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_transcoder_node[0].id} -f --access-token ${var.digital_ocean_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.transcoder-snapshot]
}
# Stop Relay Node droplet using DO CLI
resource "null_resource" "stop_node_relay" {
  count = local.cluster || local.autoscaling && var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_relay_node[0].id} -f --access-token ${var.digital_ocean_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.relay-snapshot]
}

################################################################################
# Create node group (Stream Manager API)
################################################################################

resource "null_resource" "node_group" {
  count = var.node_group_create ? 1 : 0
  triggers = {
    trigger_name  = "node-group-trigger"
    SM_IP = "${local.stream_manager_ip}"
    SM_API_KEY = "${var.stream_manager_api_key}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_IP}' '${self.triggers.SM_API_KEY}'"
  }
  provisioner "local-exec" {
    when    = create
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      NAME                       = "${var.name}"
      SM_IP                      = "${local.stream_manager_ip}"
      SM_API_KEY                 = "${var.stream_manager_api_key}"
      NODE_GROUP_REGION          ="${var.digital_ocean_region}"
      NODE_GROUP_NAME            = "${var.node_group_name}"
      ORIGINS                    = "${var.node_group_origins}"
      EDGES                      = "${var.node_group_edges}"
      TRANSCODERS                = "${var.node_group_transcoders}"
      RELAYS                     = "${var.node_group_relays}"
      ORIGIN_INSTANCE_TYPE       = "${var.node_group_origins_droplet_type}"
      EDGE_INSTANCE_TYPE         = "${var.node_group_edges_droplet_type}"
      TRANSCODER_INSTANCE_TYPE   = "${var.node_group_transcoders_droplet_type}"
      RELAY_INSTANCE_TYPE        = "${var.node_group_relays_droplet_type}"
      ORIGIN_CAPACITY            = "${var.node_group_origins_capacity}"
      EDGE_CAPACITY              = "${var.node_group_edges_capacity}"
      TRANSCODER_CAPACITY        = "${var.node_group_transcoders_capacity}"
      RELAY_CAPACITY             = "${var.node_group_relays_capacity}"
      ORIGIN_IMAGE_NAME          = "${try(digitalocean_droplet_snapshot.origin-snapshot[0].name, null)}"
      EDGE_IMAGE_NAME            = "${try(digitalocean_droplet_snapshot.edge-snapshot[0].name, null)}"
      TRANSCODER_IMAGE_NAME      = "${try(digitalocean_droplet_snapshot.transcoder-snapshot[0].name, null)}"
      RELAY_IMAGE_NAME           = "${try(digitalocean_droplet_snapshot.relay-snapshot[0].name, null)}"
    }
  }

  depends_on =  [ digitalocean_droplet.red5pro_autoscale_sm , digitalocean_droplet.red5pro_sm]
}
