locals {
  single                           = var.type == "single" ? true : false
  cluster                          = var.type == "cluster" ? true : false
  autoscaling                      = var.type == "autoscaling" ? true : false
  ssh_key                          = var.ssh_key_create ? digitalocean_ssh_key.red5pro_ssh_key[0].fingerprint : data.digitalocean_ssh_key.ssh_key_pair[0].id
  ssh_key_name                     = var.ssh_key_create ? digitalocean_ssh_key.red5pro_ssh_key[0].name : data.digitalocean_ssh_key.ssh_key_pair[0].name
  ssh_private_key                  = var.ssh_key_create ? tls_private_key.red5pro_ssh_key[0].private_key_pem : file(var.ssh_private_key_path)
  ssh_private_key_path             = var.ssh_key_create ? local_file.red5pro_ssh_key_pem[0].filename : var.ssh_private_key_path
  vpc                              = var.vpc_create ? digitalocean_vpc.red5pro_vpc[0].id : data.digitalocean_vpc.selected[0].id
  vpc_name                         = var.vpc_create ? digitalocean_vpc.red5pro_vpc[0].name : data.digitalocean_vpc.selected[0].name
  mysql_local_enable               = local.autoscaling ? false : var.mysql_database_create ? false : true
  mysql_database_create            = local.autoscaling ? true : local.cluster && var.mysql_database_create ? true : false
  mysql_host                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].host : local.cluster ? var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].private_host : "localhost" : null
  mysql_user                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].user : local.cluster ? var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].user : var.mysql_username : null
  mysql_password                   = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].password : local.cluster ? var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].password : var.mysql_password : null
  mysql_port                       = local.autoscaling ? digitalocean_database_cluster.red5pro_mysql[0].port : local.cluster ? var.mysql_database_create ? digitalocean_database_cluster.red5pro_mysql[0].port : var.mysql_port : null
  terra_host                       = local.autoscaling ? digitalocean_droplet.red5pro_terraform_service[0].ipv4_address_private : local.cluster && var.dedicated_terra_host_create ? digitalocean_droplet.red5pro_terraform_service[0].ipv4_address_private : "localhost"
  terra_host_local_enable          = local.autoscaling ? false : var.dedicated_terra_host_create ? false : true
  dedicated_terra_host_create      = local.autoscaling ? true : local.cluster && var.dedicated_terra_host_create ? true : false
  stream_manager_ip                = local.autoscaling || local.cluster ? digitalocean_droplet.red5pro_sm[0].ipv4_address : null
  single_server_ip                 = local.single ? digitalocean_droplet.red5pro_single[0].ipv4_address : null
  lb_certificate_name              = local.autoscaling && var.lb_ssl_create ? digitalocean_certificate.new_lb_cert[0].name : var.lb_exist_ssl_cert_name
  lb_ip                            = local.autoscaling ? digitalocean_loadbalancer.red5pro_lb[0].ip : null
}

################################################################################
# PROJECT SETUP IN DIGITAL OCEAN
################################################################################
resource "digitalocean_project" "do_project" {
  count       = var.do_project ? 1 : 0
  name        = var.project_name
  purpose     = "Red5Pro Deployments"
  environment = "Production"
  resources = [
              local.single ?
              digitalocean_droplet.red5pro_single[0].urn : "",

              local.cluster || local.autoscaling ?
              digitalocean_droplet.red5pro_sm[0].urn : "",

              local.mysql_database_create ?
              digitalocean_database_cluster.red5pro_mysql[0].urn : "",

              local.dedicated_terra_host_create ?
              digitalocean_droplet.red5pro_terraform_service[0].urn : "",

              var.origin_image_create ? 
              digitalocean_droplet.red5pro_origin_node[0].urn : "",

              var.edge_image_create ? 
              digitalocean_droplet.red5pro_edge_node[0].urn : "",

              var.transcoder_image_create ? 
              digitalocean_droplet.red5pro_transcoder_node[0].urn : "",

              var.relay_image_create ? 
              digitalocean_droplet.red5pro_relay_node[0].urn : "",

              local.autoscaling ? 
              digitalocean_loadbalancer.red5pro_lb[0].urn : "",
              ]
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
}

################################################################################
# VPC - Create new/existing (VPC)
################################################################################
resource "digitalocean_vpc" "red5pro_vpc" {
  count    = var.vpc_create ? 1 : 0
  ip_range = "10.5.0.0/16"
  region   = var.do_region
  name     = "${var.name}-vpc"
}

# VPC - Use existing
data "digitalocean_vpc" "selected" {
  count = var.vpc_create ? 0 : 1
  name  = var.vpc_name_existing
}

################################################################################
# Red5 Pro Single server (DO Droplet)
################################################################################
resource "digitalocean_droplet" "red5pro_single" {
  count    = local.single ? 1 : 0
  name     = "${var.name}-red5-single-${count.index}"
  region   = var.do_region
  size     = var.single_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

  connection {
    host        = digitalocean_droplet.red5pro_single[count.index].ipv4_address
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
      host        = digitalocean_droplet.red5pro_single[count.index].ipv4_address
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
  droplet_ids = [digitalocean_droplet.red5pro_sm[0].id]

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
  region   = var.do_region
  size     = var.stream_manager_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

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
      "export TF_SVC_LOCAL_ENABLE='${local.terra_host_local_enable}'",
      "export TERRA_HOST='${local.terra_host}'",
      "export TERRA_API_TOKEN='${var.terra_api_token}'",
      "export TERRA_PARALLELISM='${var.terra_parallelism}'",
      "export DO_API_TOKEN='${var.do_token}'",
      "export SSH_KEY_NAME='${local.ssh_key_name}'",
      "export DB_HOST='${local.mysql_host}'",
      "export DB_PORT='${local.mysql_port}'",
      "export DB_USER='${local.mysql_user}'",
      "export DB_PASSWORD='${nonsensitive(local.mysql_password)}'",
      ###################################      
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_install_mysql_local.sh",
      "sudo -E /home/red5pro-installer/r5p_install_terraform_svc_local.sh",
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

################################################################################
# Stream manager - Database MySQL Configuration
################################################################################
# Stream Manager Database Digital Ocean
resource "digitalocean_database_cluster" "red5pro_mysql" {
  count      = local.mysql_database_create ? 1 : 0
  name       = "${var.name}-mysql-sm-db"
  region     = var.do_region
  version    = "8"
  size       = var.mysql_database_size
  node_count = 1
  engine     = "mysql"
  private_network_uuid = local.vpc
}

# Allowing stream manager and terraform service droplet to access the MySQL Database
resource "digitalocean_database_firewall" "database_fw" {
  count      = local.mysql_database_create ? 1 : 0
  cluster_id = digitalocean_database_cluster.red5pro_mysql[0].id

  rule {
    type     = "droplet"
    value    = digitalocean_droplet.red5pro_sm[0].id
  }
  rule {
    type     = "droplet"
    value    = var.dedicated_terra_host_create ? digitalocean_droplet.red5pro_terraform_service[0].id : digitalocean_droplet.red5pro_sm[0].id
  }
}

################################################################################
# DO droplet Terraform Service
################################################################################
resource "digitalocean_droplet" "red5pro_terraform_service" {
  count    = local.dedicated_terra_host_create ? 1 : 0
  name     = "${var.name}-red5-terraform-service"
  region   = var.do_region
  size     = var.terraform_service_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

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
      "export DO_API_TOKEN='${var.do_token}'",
      "export SSH_KEY_NAME='${local.ssh_key_name}'",
      "export TERRA_HOST='${self.ipv4_address_private}'",
      "export TERRA_API_TOKEN='${var.terra_api_token}'",
      "export TERRA_PARALLELISM='${var.terra_parallelism}'",
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
  count       = local.dedicated_terra_host_create ? 1 : 0
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
  count = local.autoscaling ? 1 : 0
  name   = "${var.name}-red5pro-lb"
  region = var.do_region
  size_unit = var.lb_size_count

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = var.https_letsencrypt_enable ? 443 : 5080
    target_protocol = var.https_letsencrypt_enable ? "https" : "http"

    certificate_name = local.lb_certificate_name
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

  vpc_uuid = local.vpc
  droplet_ids = [digitalocean_droplet.red5pro_sm[0].id]
}

# Load Balancer Certificate 
resource "digitalocean_certificate" "new_lb_cert" {
  count            = var.lb_ssl_create && local.autoscaling ? 1 : 0
  name             = "${var.name}-lb-ssl-cert"
  type             = var.lb_ssl_certificate_type

  domains          = var.lb_ssl_certificate_type == "lets_encrypt" ? [var.existing_lb_domain_name] : null

  private_key = var.lb_ssl_certificate_type == "custom" ? file(var.cert_private_key) : null
  leaf_certificate = var.lb_ssl_certificate_type == "custom" ? file(var.leaf_public_cert) : null
  certificate_chain = var.lb_ssl_certificate_type == "custom" ? file(var.cert_fullchain) : null

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# Red5 Pro Autoscaling Nodes - Origin/Edge/Transcoders/Relay (DO Droplet)
################################################################################

# Origin Node droplet for DO Custom Image
resource "digitalocean_droplet" "red5pro_origin_node" {
  count    = var.origin_image_create ? 1 : 0
  name     = "${var.name}-node-origin-image"
  region   = var.do_region
  size     = var.origin_image_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

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
  count    = var.edge_image_create ? 1 : 0
  name     = "${var.name}-node-edge-image"
  region   = var.do_region
  size     = var.edge_image_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

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
  count    = var.transcoder_image_create ? 1 : 0
  name     = "${var.name}-node-transcoder-image"
  region   = var.do_region
  size     = var.transcoder_image_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

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
  count    = var.relay_image_create ? 1 : 0
  name     = "${var.name}-node-relay-image"
  region   = var.do_region
  size     = var.relay_image_droplet_size
  image    = "ubuntu-20-04-x64"
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc

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
# Origin node - Create image
resource "digitalocean_droplet_snapshot" "origin-snapshot" {
  count          = var.origin_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_origin_node[0].id
  name           = "${var.name}-node-origin-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_origin_node]
}

# Edge node - Create image
resource "digitalocean_droplet_snapshot" "edge-snapshot" {
  count          = var.edge_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_edge_node[0].id
  name           = "${var.name}-node-edge-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_edge_node]
}

# Transcode node - Create image
resource "digitalocean_droplet_snapshot" "transcoder-snapshot" {
  count          = var.transcoder_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_transcoder_node[0].id
  name           = "${var.name}-node-transcoder-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_transcoder_node]
}

# Relay node - Create image
resource "digitalocean_droplet_snapshot" "relay-snapshot" {
  count          = var.relay_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_relay_node[0].id
  name           = "${var.name}-node-relay-custom-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [digitalocean_droplet.red5pro_relay_node]
}

################################################################################
# Stop droplet which used for creating DO custom images (DO CLI)
################################################################################
# Stop Origin Node droplet using DO CLI
resource "null_resource" "stop_node_origin" {
  count = var.origin_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_origin_node[0].id} -f --access-token ${var.do_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.origin-snapshot]
}
# Stop Edge Node droplet using DO CLI
resource "null_resource" "stop_node_edge" {
  count = var.edge_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_edge_node[0].id} -f --access-token ${var.do_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.edge-snapshot]
}
# Stop Transcoder Node droplet using DO CLI
resource "null_resource" "stop_node_transcoder" {
  count = var.transcoder_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_transcoder_node[0].id} -f --access-token ${var.do_token}"
  }
  depends_on     = [digitalocean_droplet_snapshot.transcoder-snapshot]
}
# Stop Relay Node droplet using DO CLI
resource "null_resource" "stop_node_relay" {
  count = var.relay_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_relay_node[0].id} -f --access-token ${var.do_token}"
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
    when    = create
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      NAME = "${var.name}"
      SM_IP = "${local.stream_manager_ip}"
      SM_API_KEY = "${var.stream_manager_api_key}"
      NODE_GROUP_REGION ="${var.do_region}"
      NODE_GROUP_NAME = "${var.node_group_name}"
      ORIGINS = "${var.node_group_origins}"
      EDGES = "${var.node_group_edges}"
      TRANSCODERS = "${var.node_group_transcoders}"
      RELAYS = "${var.node_group_relays}"
      ORIGIN_INSTANCE_TYPE = "${var.node_group_origins_droplet_type}"
      EDGE_INSTANCE_TYPE = "${var.node_group_edges_droplet_type}"
      TRANSCODER_INSTANCE_TYPE = "${var.node_group_transcoders_droplet_type}"
      RELAY_INSTANCE_TYPE = "${var.node_group_relays_droplet_type}"
      ORIGIN_CAPACITY = "${var.node_group_origins_capacity}"
      EDGE_CAPACITY = "${var.node_group_edges_capacity}"
      TRANSCODER_CAPACITY = "${var.node_group_transcoders_capacity}"
      RELAY_CAPACITY = "${var.node_group_relays_capacity}"
      ORIGIN_IMAGE_NAME = "${try(digitalocean_droplet_snapshot.origin-snapshot[0].name, null)}"
      EDGE_IMAGE_NAME = "${try(digitalocean_droplet_snapshot.edge-snapshot[0].name, null)}"
      TRANSCODER_IMAGE_NAME = "${try(digitalocean_droplet_snapshot.transcoder-snapshot[0].name, null)}"
      RELAY_IMAGE_NAME = "${try(digitalocean_droplet_snapshot.relay-snapshot[0].name, null)}"
    }
  }
    provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_IP}' '${self.triggers.SM_API_KEY}'"
  }

  depends_on = [digitalocean_droplet.red5pro_sm[0]]
}
