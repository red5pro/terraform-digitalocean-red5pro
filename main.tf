locals {
  standalone                      = var.type == "standalone" ? true : false
  cluster                         = var.type == "cluster" ? true : false
  autoscale                       = var.type == "autoscale" ? true : false
  cluster_or_autoscale            = local.cluster || local.autoscale ? true : false
  ssh_key_name                    = var.ssh_key_use_existing ? data.digitalocean_ssh_key.ssh_key_pair[0].name : digitalocean_ssh_key.red5pro_ssh_key[0].name
  ssh_key_public                  = var.ssh_key_use_existing ? data.digitalocean_ssh_key.ssh_key_pair[0].id :digitalocean_ssh_key.red5pro_ssh_key[0].fingerprint
  ssh_private_key                 = var.ssh_key_use_existing ? file(var.ssh_key_private_key_path_existing) : tls_private_key.red5pro_ssh_key[0].private_key_pem
  ssh_private_key_path            = var.ssh_key_use_existing ? var.ssh_key_private_key_path_existing : local_file.red5pro_ssh_key_pem[0].filename 
  vpc_id                          = var.vpc_use_existing ? data.digitalocean_vpc.existing_vpc[0].id :digitalocean_vpc.red5pro_vpc[0].id
  vpc_name                        = var.vpc_use_existing ? data.digitalocean_vpc.existing_vpc[0].name : digitalocean_vpc.red5pro_vpc[0].name
  standalone_server_ip            = local.standalone ? var.standalone_server_reserved_ip_use_existing ? data.digitalocean_reserved_ip.existing_standalone_server_reserved_ip[0].ip_address : digitalocean_reserved_ip.red5pro_standalone_reserved_ip[0].ip_address : "null"
  load_balancer_ip                = local.autoscale ? digitalocean_loadbalancer.red5pro_lb[0].ip : "null"
  load_balancer_certificate_name  = local.autoscale && var.create_load_balancer_with_ssl ? digitalocean_certificate.new_lb_cert[0].name : null
  stream_manager_ip               = local.autoscale ? digitalocean_loadbalancer.red5pro_lb[0].ip : local.cluster ? var.stream_manager_reserved_ip_use_existing ? data.digitalocean_reserved_ip.existing_sm_reserved_ip[0].ip_address : digitalocean_reserved_ip.red5pro_sm_reserved_ip[0].ip_address : "null"  
  stream_managers_amount          = local.autoscale ? var.stream_managers_amount : local.cluster ? 1 : 0
  stream_manager_ssl              = local.autoscale ? "none" : var.https_ssl_certificate
  stream_manager_standalone       = local.autoscale ? false : true
  stream_manager_autoscale        = local.autoscale ? true : false
  stream_managers_id              = [ for red5pro_sm in digitalocean_droplet.red5pro_sm : red5pro_sm.id ]
  stream_managers_urn             = [ for red5pro_sm in digitalocean_droplet.red5pro_sm : red5pro_sm.urn ]
  kafka_ip                        = local.cluster_or_autoscale ? local.kafka_standalone_instance ? digitalocean_droplet.red5pro_kafka_standalone[0].ipv4_address_private : digitalocean_droplet.red5pro_sm[0].ipv4_address_private : "null"
  kafka_on_sm_replicas            = local.kafka_standalone_instance ? 0 : 1
  kafka_ssl_keystore_key          = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", trimspace(tls_private_key.kafka_server_key[0].private_key_pem_pkcs8)))) : "null"
  kafka_ssl_truststore_cert       = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", tls_self_signed_cert.ca_cert[0].cert_pem))) : "null"
  kafka_ssl_keystore_cert_chain   = local.cluster_or_autoscale ? nonsensitive(join("\\\\n", split("\n", tls_locally_signed_cert.kafka_server_cert[0].cert_pem))) : "null"
  kafka_standalone_instance       = local.autoscale ? true : local.cluster && var.kafka_standalone_instance_create ? true : false
  kafka_standalone_dedicated      = local.autoscale ? true : local.cluster && var.kafka_standalone_instance_create ? true : false
  digital_ocean_project_name      = var.digital_ocean_project_use_existing ? var.digital_ocean_existing_project_name : digitalocean_project.do_project[0].name
  digital_ocean_project_resources = concat(
    compact([ local.standalone ? digitalocean_droplet.red5pro_standalone[0].urn : "" ]),
    compact([ local.cluster ? digitalocean_droplet.red5pro_sm[0].urn : "" ]),
    compact([ local.kafka_standalone_dedicated ? digitalocean_droplet.red5pro_kafka_standalone[0].urn : "" ]),
    compact([ var.node_image_create ? digitalocean_droplet.red5pro_node_instance[0].urn : "" ]),
    compact([ local.autoscale ? digitalocean_loadbalancer.red5pro_lb[0].urn : "" ]),
    compact(local.stream_managers_urn)
  )
}

################################################################################
# PROJECT SETUP IN DIGITAL OCEAN
################################################################################

data "digitalocean_project" "existing_do_project" {
  count = var.digital_ocean_project_use_existing ? 1 : 0
  name  = var.digital_ocean_existing_project_name
}

resource "digitalocean_project_resources" "do_project" {
  count       = var.digital_ocean_project_use_existing ? 1 : 0
  project     = data.digitalocean_project.existing_do_project[0].id
  resources   = local.digital_ocean_project_resources
}

resource "digitalocean_project" "do_project" {
  count       = var.digital_ocean_project_use_existing ? 0 : 1
  name        = "${var.name}-Red5Pro"
  purpose     = "${var.name}-Red5Pro Deployments"
  environment = "Production"
  resources   = local.digital_ocean_project_resources
}

resource "digitalocean_tag" "red5pro_tag" {
  name        = "${var.name}-red5-deployment"
}

################################################################################
# SSH_KEY
################################################################################
# SSH key pair generation
resource "tls_private_key" "red5pro_ssh_key" {
  count     = var.ssh_key_use_existing ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Import SSH key pair to DO
resource "digitalocean_ssh_key" "red5pro_ssh_key" {
  count      = var.ssh_key_use_existing ? 0 : 1
  name       = "${var.name}-ssh"
  public_key = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Save SSH key pair files to local folder
resource "local_file" "red5pro_ssh_key_pem" {
  count           = var.ssh_key_use_existing ? 0 : 1
  filename        = "./${var.name}-ssh.pem"
  content         = tls_private_key.red5pro_ssh_key[0].private_key_pem
  file_permission = "0400"
}

resource "local_file" "red5pro_ssh_key_pub" {
  count    = var.ssh_key_use_existing ? 0 : 1
  filename = "./${var.name}-ssh.pub"
  content  = tls_private_key.red5pro_ssh_key[0].public_key_openssh
}

# Check current SSH key pair on the DO
data "digitalocean_ssh_key" "ssh_key_pair" {
  count = var.ssh_key_use_existing ? 1 : 0
  name  = var.ssh_key_name_existing
  lifecycle {
    postcondition {
      condition =    self.name != null && self.name != ""
      error_message = "ERROR! No SSH keys found with name ${var.ssh_key_name_existing} in Digital Ocean Account."
    }
  }
}

################################################################################
# VPC - Create new/existing (VPC)
################################################################################
resource "digitalocean_vpc" "red5pro_vpc" {
  count    = var.vpc_use_existing ? 0 : 1
  ip_range = var.vpc_cidr_block
  region   = var.digital_ocean_region
  name     = "${var.name}-vpc"
}

# VPC - Use existing
data "digitalocean_vpc" "existing_vpc" {
  count = var.vpc_use_existing ? 1 : 0
  name  = var.vpc_name_existing
  lifecycle {
    postcondition {
      condition     = self.name != null && self.name != ""
      error_message = "ERROR! VPC name ${var.vpc_name_existing} does not exist in the Digital Ocean Account"
    }
  }
}

################################################################################
# Red5 Pro Standalone server (DO Droplet)
################################################################################
resource "digitalocean_reserved_ip" "red5pro_standalone_reserved_ip" {
  count    =  local.cluster || local.autoscale ? 0 : local.standalone && var.standalone_server_reserved_ip_use_existing ? 0 : 1
  region   = var.digital_ocean_region
}

data "digitalocean_reserved_ip" "existing_standalone_server_reserved_ip" {
  count      = local.autoscale || local.cluster ? 0 : local.standalone && var.standalone_server_reserved_ip_use_existing ? 1 : 0
  ip_address = var.standalone_server_existing_reserved_ip_address
  lifecycle {
    postcondition {
      condition     = self.urn != null && self.region == var.digital_ocean_region
      error_message = "Reserved IP address ${var.standalone_server_existing_reserved_ip_address} does not exist in region ${var.digital_ocean_region}."
    }
  }
}

resource "random_password" "ssl_password_red5pro_standalone" {
  count   = local.standalone && var.https_ssl_certificate != "none" ? 1 : 0
  length  = 16
  special = false
}

resource "digitalocean_reserved_ip_assignment" "standalone_server_ip_association" {
  count      = local.standalone ? 1 : 0
  ip_address = local.standalone_server_ip
  droplet_id =  digitalocean_droplet.red5pro_standalone[0].id
}

resource "digitalocean_droplet" "red5pro_standalone" {
  count    = local.standalone ? 1 : 0
  name     = "${var.name}-red5-standalone"
  region   = var.digital_ocean_region
  size     = var.standalone_server_droplet_size
  image    = lookup(var.ubuntu_image_version, var.ubuntu_version, "what?")
  ssh_keys = [local.ssh_key_public]
  vpc_uuid = local.vpc_id
  tags     = [digitalocean_tag.red5pro_tag.id]

  connection {
    host        = self.ipv4_address
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
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "export NODE_INSPECTOR_ENABLE='${var.standalone_red5pro_inspector_enable}'",
      "export NODE_RESTREAMER_ENABLE='${var.standalone_red5pro_restreamer_enable}'",
      "export NODE_SOCIALPUSHER_ENABLE='${var.standalone_red5pro_socialpusher_enable}'",
      "export NODE_SUPPRESSOR_ENABLE='${var.standalone_red5pro_suppressor_enable}'",
      "export NODE_HLS_ENABLE='${var.standalone_red5pro_hls_enable}'",
      "export NODE_ROUND_TRIP_AUTH_ENABLE='${var.standalone_red5pro_round_trip_auth_enable}'",
      "export NODE_ROUND_TRIP_AUTH_HOST='${var.standalone_red5pro_round_trip_auth_host}'",
      "export NODE_ROUND_TRIP_AUTH_PORT='${var.standalone_red5pro_round_trip_auth_port}'",
      "export NODE_ROUND_TRIP_AUTH_PROTOCOL='${var.standalone_red5pro_round_trip_auth_protocol}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE='${var.standalone_red5pro_round_trip_auth_endpoint_validate}'",
      "export NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE='${var.standalone_red5pro_round_trip_auth_endpoint_invalidate}'",
      "export NODE_CLOUDSTORAGE_ENABLE='${var.standalone_red5pro_cloudstorage_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_ACCESS_KEY='${var.standalone_red5pro_cloudstorage_digitalocean_spaces_access_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_SECRET_KEY='${var.standalone_red5pro_cloudstorage_digitalocean_spaces_secret_key}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_BUCKET_NAME='${var.standalone_red5pro_cloudstorage_digitalocean_spaces_name}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_REGION='${var.standalone_red5pro_cloudstorage_digitalocean_spaces_region}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_ENABLE='${var.standalone_red5pro_cloudstorage_postprocessor_enable}'",
      "export NODE_CLOUDSTORAGE_DIGITALOCEAN_SPACES_FILE_ACCESS='${var.standalone_red5pro_cloudstorage_spaces_file_access}'",
      "export NODE_CLOUDSTORAGE_POSTPROCESSOR_MP4_ENABLE='${var.standalone_red5pro_cloudstorage_postprocessor_mp4_enable}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node_apps_plugins.sh",
      "sudo systemctl daemon-reload && sudo systemctl start red5pro",
      "sudo mkdir -p /usr/local/red5pro/certs",
      "echo '${try(file(var.https_ssl_certificate_cert_path), "")}' | sudo tee -a /usr/local/red5pro/certs/fullchain.pem",
      "echo '${try(file(var.https_ssl_certificate_key_path), "")}' | sudo tee -a /usr/local/red5pro/certs/privkey.pem",
      "export SSL='${var.https_ssl_certificate}'",
      "export SSL_DOMAIN='${var.https_ssl_certificate_domain_name}'",
      "export SSL_MAIL='${var.https_ssl_certificate_email}'",
      "export SSL_PASSWORD='${try(nonsensitive(random_password.ssl_password_red5pro_standalone[0].result), "")}'",
      "export SSL_CERT_PATH=/usr/local/red5pro/certs",
      "nohup sudo -E /home/red5pro-installer/r5p_ssl_check_install.sh >> /home/red5pro-installer/r5p_ssl_check_install.log &",
      "sleep 2"

    ]
    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

################################################################################
# Firewall for Standalone Red5Pro server (DO Droplet)
################################################################################
# Firewall for standalone red5pro droplet
resource "digitalocean_firewall" "red5pro_standalone_firewall" {
  count       = local.standalone ? 1 : 0
  name        = "${var.name}-standalone-firewall"
  droplet_ids = [digitalocean_droplet.red5pro_standalone[0].id]

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

# Firewall for Stream Manger red5pro droplet
resource "digitalocean_firewall" "red5pro_sm_firewall" {
  count       = local.cluster_or_autoscale ? 1 : 0
  name        = "${var.name}-stream-manager-firewall"
  droplet_ids = local.stream_managers_id

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
resource "digitalocean_reserved_ip" "red5pro_sm_reserved_ip" {
  count    =  local.standalone || local.autoscale ? 0 : local.cluster && var.stream_manager_reserved_ip_use_existing ? 0 : 1
  region   = var.digital_ocean_region
}

data "digitalocean_reserved_ip" "existing_sm_reserved_ip" {
  count      = local.standalone || local.autoscale ? 0 : local.cluster && var.stream_manager_reserved_ip_use_existing ? 1 : 0
  ip_address = var.stream_manager_existing_reserved_ip_address
  lifecycle {
    postcondition {
      condition     = self.urn != null && self.region == var.digital_ocean_region
      error_message = "Reserved IP address ${var.stream_manager_existing_reserved_ip_address} does not exist in region ${var.digital_ocean_region}."
    }
  }
}

resource "digitalocean_reserved_ip_assignment" "sm_ip_association" {
  count      = local.cluster ? 1 : 0
  ip_address = local.stream_manager_ip
  droplet_id =  digitalocean_droplet.red5pro_sm[0].id
  depends_on = [ digitalocean_project_resources.do_project[0], digitalocean_project.do_project[0]]
}

# Generate random password for Red5 Pro Stream Manager 2.0 authentication
resource "random_password" "r5as_auth_secret" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 32
  special = false
}

# Stream Manager droplet
resource "digitalocean_droplet" "red5pro_sm" {
  count    = local.autoscale ? var.stream_managers_amount : local.cluster ? 1 : 0
  name     = local.stream_managers_amount == 1 ? "${var.name}-red5-sm" : "${var.name}-red5-sm-${count.index+1}"
  region   = var.digital_ocean_region
  size     = var.stream_manager_droplet_size
  image    = lookup(var.ubuntu_image_version, var.ubuntu_version, "what?")
  ssh_keys = [local.ssh_key_public]
  vpc_uuid = local.vpc_id
  tags     = [digitalocean_tag.red5pro_tag.id]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /usr/local/stream-manager/certs
    echo "${try(file(var.https_ssl_certificate_cert_path), "")}" > /usr/local/stream-manager/certs/cert.pem
    echo "${try(file(var.https_ssl_certificate_key_path), "")}" > /usr/local/stream-manager/certs/privkey.pem
    ############################ .env file #########################################################
    cat >> /usr/local/stream-manager/.env <<- EOM
    KAFKA_CLUSTER_ID=${random_id.kafka_cluster_id[0].b64_std}
    KAFKA_ADMIN_USERNAME=${random_string.kafka_admin_username[0].result}
    KAFKA_ADMIN_PASSWORD=${random_id.kafka_admin_password[0].id}
    KAFKA_CLIENT_USERNAME=${random_string.kafka_client_username[0].result}
    KAFKA_CLIENT_PASSWORD=${random_id.kafka_client_password[0].id}
    R5AS_AUTH_SECRET=${random_password.r5as_auth_secret[0].result}
    R5AS_AUTH_USER=${var.stream_manager_auth_user}
    R5AS_AUTH_PASS=${var.stream_manager_auth_password}
    TF_VAR_digitalocean_api_token=${var.digital_ocean_access_token}
    TF_VAR_digitalocean_ssh_key_name=${local.ssh_key_name}
    TF_VAR_r5p_license_key=${var.red5pro_license_key}
    TRAEFIK_TLS_CHALLENGE=${local.stream_manager_ssl == "letsencrypt" ? "true" : "false"}
    TRAEFIK_HOST=${var.https_ssl_certificate_domain_name}
    TRAEFIK_SSL_EMAIL=${var.https_ssl_certificate_email}
    TRAEFIK_CMD=${local.stream_manager_ssl == "imported" ? "--providers.file.filename=/scripts/traefik.yaml" : ""}
  EOF
}

resource "null_resource" "red5pro_sm_configuration" {
  count = local.stream_managers_amount

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo cloud-init status --wait",
      "echo 'KAFKA_SSL_KEYSTORE_KEY=${local.kafka_ssl_keystore_key}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_SSL_TRUSTSTORE_CERTIFICATES=${local.kafka_ssl_truststore_cert}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_SSL_KEYSTORE_CERTIFICATE_CHAIN=${local.kafka_ssl_keystore_cert_chain}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_REPLICAS=${local.kafka_on_sm_replicas}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'KAFKA_IP=${local.kafka_ip}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'TRAEFIK_IP=${local.stream_manager_ip}' | sudo tee -a /usr/local/stream-manager/.env",
      "echo 'TF_VAR_digitalocean_project_name=${local.digital_ocean_project_name}' | sudo tee -a /usr/local/stream-manager/.env",
      "export SM_SSL='${local.stream_manager_ssl}'",
      "export SM_STANDALONE='${local.stream_manager_standalone}'",
      "export SM_AUTOSCALE='${local.stream_manager_autoscale}'",
      "export SM_SSL_DOMAIN='${var.https_ssl_certificate_domain_name}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_sm2_do.sh",
    ]
    connection {
      host        = digitalocean_droplet.red5pro_sm[count.index].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
  depends_on = [tls_cert_request.kafka_server_csr, null_resource.red5pro_kafka_standalone_configuration]
}

################################################################################
# Kafka keys and certificates
################################################################################
# Generate random admin usernames for Kafka cluster
resource "random_string" "kafka_admin_username" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

# Generate random client usernames for Kafka cluster
resource "random_string" "kafka_client_username" {
  count   = local.cluster_or_autoscale ? 1 : 0
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}

# Generate random IDs for Kafka cluster
resource "random_id" "kafka_cluster_id" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Generate random passwords for Kafka cluster
resource "random_id" "kafka_admin_password" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Generate random passwords for Kafka cluster
resource "random_id" "kafka_client_password" {
  count       = local.cluster_or_autoscale ? 1 : 0
  byte_length = 16
}

# Create private key for CA
resource "tls_private_key" "ca_private_key" {
  count     = local.cluster_or_autoscale ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create private key for kafka server certificate 
resource "tls_private_key" "kafka_server_key" {
  count     = local.cluster_or_autoscale ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create self-signed certificate for CA
resource "tls_self_signed_cert" "ca_cert" {
  count             = local.cluster_or_autoscale ? 1 : 0
  private_key_pem   = tls_private_key.ca_private_key[0].private_key_pem
  is_ca_certificate = true

  subject {
    country             = "US"
    common_name         = "Infrared5, Inc."
    organization        = "Red5"
    organizational_unit = "Red5 Root Certification Auhtority"
  }

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "cert_signing",
    "crl_signing",
  ]
}

# Create CSR for server certificate 
resource "tls_cert_request" "kafka_server_csr" {
  count           = local.cluster_or_autoscale ? 1 : 0
  private_key_pem = tls_private_key.kafka_server_key[0].private_key_pem
  ip_addresses    = [local.kafka_ip]
  dns_names       = ["kafka0"]

  subject {
    country             = "US"
    common_name         = "Kafka server"
    organization        = "Infrared5, Inc."
    organizational_unit = "Development"
  }

  depends_on = [digitalocean_droplet.red5pro_sm[0], digitalocean_droplet.red5pro_kafka_standalone[0]]
}

# Sign kafka server Certificate by Private CA 
resource "tls_locally_signed_cert" "kafka_server_cert" {
  count              = local.cluster_or_autoscale ? 1 : 0
  cert_request_pem   = tls_cert_request.kafka_server_csr[0].cert_request_pem
  ca_private_key_pem = tls_private_key.ca_private_key[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert[0].cert_pem

  validity_period_hours = 1 * 365 * 24

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "digitalocean_droplet" "red5pro_kafka_standalone" {
  count    = local.kafka_standalone_dedicated ? 1 : 0
  name     = "${var.name}-kafka-standalone"
  region   = var.digital_ocean_region
  size     = var.kafka_standalone_droplet_size
  image    = lookup(var.ubuntu_image_version, var.ubuntu_version, "what?")
  ssh_keys = [local.ssh_key_public]
  vpc_uuid = local.vpc_id
  tags     = [digitalocean_tag.red5pro_tag.id]
}

resource "null_resource" "red5pro_kafka_standalone_configuration" {
  count = local.kafka_standalone_instance ? 1 : 0
  connection {
    host        = digitalocean_droplet.red5pro_kafka_standalone[0].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = local.ssh_private_key
  }

  provisioner "file" {
    source      = "${abspath(path.module)}/red5pro-installer"
    destination = "/home"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables -F",
      "sudo cloud-init status --wait",
      "echo 'ssl.keystore.key=${local.kafka_ssl_keystore_key}' | sudo tee -a /home/red5pro-installer/server.properties",
      "echo 'ssl.truststore.certificates=${local.kafka_ssl_truststore_cert}' | sudo tee -a /home/red5pro-installer/server.properties",
      "echo 'ssl.keystore.certificate.chain=${local.kafka_ssl_keystore_cert_chain}' | sudo tee -a /home/red5pro-installer/server.properties",
      "echo 'listener.name.broker.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${nonsensitive(random_string.kafka_admin_username[0].result)}\" password=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_admin_username[0].result)}=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_client_username[0].result)}=\"${nonsensitive(random_id.kafka_client_password[0].id)}\";' | sudo tee -a /home/red5pro-installer/server.properties",
      "echo 'listener.name.controller.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${nonsensitive(random_string.kafka_admin_username[0].result)}\" password=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_admin_username[0].result)}=\"${nonsensitive(random_id.kafka_admin_password[0].id)}\" user_${nonsensitive(random_string.kafka_client_username[0].result)}=\"${nonsensitive(random_id.kafka_client_password[0].id)}\";' | sudo tee -a /home/red5pro-installer/server.properties",
      "echo 'advertised.listeners=BROKER://${local.kafka_ip}:9092' | sudo tee -a /home/red5pro-installer/server.properties",
      "export KAFKA_ARCHIVE_URL='${var.kafka_standalone_instance_arhive_url}'",
      "export KAFKA_CLUSTER_ID='${random_id.kafka_cluster_id[0].b64_std}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_kafka_install.sh",
    ]
    connection {
      host        = digitalocean_droplet.red5pro_kafka_standalone[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
  depends_on = [tls_cert_request.kafka_server_csr]
}

# Firewall for Terraform Service droplet
resource "digitalocean_firewall" "red5pro_kafka_standalone_firewall" {
  count       = local.kafka_standalone_dedicated ? 1 : 0
  name        = "${var.name}-kafka-standalone-firewall"
  droplet_ids = [digitalocean_droplet.red5pro_kafka_standalone[0].id]

  dynamic "inbound_rule" {
    for_each = var.firewall_kafka_standalone_inbound
    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
    }
  }

  dynamic "outbound_rule" {
    for_each = var.firewall_kafka_standalone_outbound
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
  count  = local.autoscale ? 1 : 0
  name   = "${var.name}-red5pro-lb"
  region = var.digital_ocean_region
  size   = var.load_balancer_size

  forwarding_rule {
    entry_port     = var.create_load_balancer_with_ssl ? 443 : 80
    entry_protocol = var.create_load_balancer_with_ssl ? "https" : "http"

    target_port     = 80
    target_protocol = "http"

    certificate_name = local.load_balancer_certificate_name
  }
  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  sticky_sessions {
    type = "cookies"
    cookie_name = "${var.name}-lb-cookie"
    cookie_ttl_seconds = 300
  }

  vpc_uuid = local.vpc_id
  droplet_ids = local.stream_managers_id
  depends_on = [ digitalocean_droplet.red5pro_sm ]
}

# Load Balancer Certificate 
resource "digitalocean_certificate" "new_lb_cert" {
  count            = var.create_load_balancer_with_ssl && local.autoscale ? 1 : 0
  name             = "${var.name}-lb-ssl-cert"
  type             = "custom"
  private_key       = file(var.load_balancer_cert_private_key)
  leaf_certificate  = file(var.load_balancer_cert_public)
  certificate_chain = file(var.load_balancer_cert_chain)

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Red5 Pro Autoscale Nodes Instances
################################################################################
# Node droplet for DO Custom Image
resource "digitalocean_droplet" "red5pro_node_instance" {
  count    = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  name     = "${var.name}-node-image"
  region   = var.digital_ocean_region
  size     = var.node_image_droplet_size
  image    = lookup(var.ubuntu_image_version, var.ubuntu_version, "what?")
  ssh_keys = [local.ssh_key_public]
  vpc_uuid = local.vpc_id
  tags     = [digitalocean_tag.red5pro_tag.id]

  connection {
    host        = digitalocean_droplet.red5pro_node_instance[0].ipv4_address
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
      "export NODE_API_ENABLE='${var.red5pro_api_enable}'",
      "export NODE_API_KEY='${var.red5pro_api_key}'",
      "cd /home/red5pro-installer/",
      "sudo chmod +x /home/red5pro-installer/*.sh",
      "sudo -E /home/red5pro-installer/r5p_install_server_basic.sh",
      "sudo -E /home/red5pro-installer/r5p_config_node.sh",
      "sudo -E /home/red5pro-installer/r5p_cleanup_node.sh",
      "sleep 2"
    ]
    connection {
      host        = digitalocean_droplet.red5pro_node_instance[0].ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }
}

#####################################
# Red5 Pro Autoscale Nodes image
#####################################
# Node - Create image
resource "digitalocean_droplet_snapshot" "node-snapshot" {
  count          = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  droplet_id     = digitalocean_droplet.red5pro_node_instance[0].id
  name           = "${var.name}-node-image-${formatdate("DDMMMYY-hhmm", timestamp())}"
  depends_on     = [null_resource.poweroff_node_instance]
  lifecycle {
    ignore_changes = [ name ]
  }
}

################################################################################
# Delete droplets which used for creating DO custom images (DO CLI)
################################################################################
resource "null_resource" "poweroff_node_instance" {
  count = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet-action power-off ${digitalocean_droplet.red5pro_node_instance[0].id} --wait"
    environment = {
      DIGITALOCEAN_ACCESS_TOKEN = "${var.digital_ocean_access_token}"
    }
  }
  depends_on     = [digitalocean_droplet.red5pro_node_instance]
}

resource "null_resource" "delete_node_instance" {
  count = local.cluster_or_autoscale && var.node_image_create ? 1 : 0
  provisioner "local-exec" {
    command = "doctl compute droplet delete ${digitalocean_droplet.red5pro_node_instance[0].id} -f"
    environment = {
      DIGITALOCEAN_ACCESS_TOKEN = "${var.digital_ocean_access_token}"
    }
  }
  depends_on     = [digitalocean_droplet_snapshot.node-snapshot]
}

################################################################################
# Create/Delete node group (Stream Manager API)
################################################################################
resource "time_sleep" "wait_for_delete_nodegroup" {
  count            = var.node_group_create ? 1 : 0
  depends_on = [ 
    local.stream_managers_id,
    digitalocean_firewall.red5pro_sm_firewall[0],
    digitalocean_droplet.red5pro_kafka_standalone[0],
    digitalocean_firewall.red5pro_kafka_standalone_firewall[0],
    digitalocean_loadbalancer.red5pro_lb[0],
    null_resource.red5pro_sm_configuration,
    null_resource.red5pro_kafka_standalone_configuration[0],
  ]
  destroy_duration = "90s"
}

resource "null_resource" "node_group" {
  count = local.cluster_or_autoscale && var.node_group_create ? 1 : 0
  triggers = {
    trigger_name   = "node-group-trigger"
    SM_IP          = "${local.stream_manager_ip}"
    R5AS_AUTH_USER = "${var.stream_manager_auth_user}"
    R5AS_AUTH_PASS = "${var.stream_manager_auth_password}"
  }
  provisioner "local-exec" {
    when    = create
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_create_node_group.sh"
    environment = {
      SM_IP                                    = "${local.stream_manager_ip}"
      R5AS_AUTH_USER                           = "${var.stream_manager_auth_user}"
      R5AS_AUTH_PASS                           = "${var.stream_manager_auth_password}"
      NODE_GROUP_REGION                        = "${var.digital_ocean_region}"
      NODE_ENVIRONMENT                         = "${var.name}"
      NODE_VPC_NAME                            = "${local.vpc_name}"
      NODE_IMAGE_NAME                          = "${digitalocean_droplet_snapshot.node-snapshot[0].name}"
      ORIGINS_MIN                              = "${var.node_group_origins_min}"
      ORIGINS_MAX                              = "${var.node_group_origins_max}"
      ORIGIN_INSTANCE_TYPE                     = "${var.node_group_origins_droplet_size}"
      ORIGIN_VOLUME_SIZE                       = "${var.node_group_origins_volume_size}"
      EDGES_MIN                                = "${var.node_group_edges_min}"
      EDGES_MAX                                = "${var.node_group_edges_max}"
      EDGE_INSTANCE_TYPE                       = "${var.node_group_edges_droplet_size}"
      EDGE_VOLUME_SIZE                         = "${var.node_group_edges_volume_size}"
      TRANSCODERS_MIN                          = "${var.node_group_transcoders_min}"
      TRANSCODERS_MAX                          = "${var.node_group_transcoders_max}"
      TRANSCODER_INSTANCE_TYPE                 = "${var.node_group_transcoders_droplet_size}"
      TRANSCODER_VOLUME_SIZE                   = "${var.node_group_transcoders_volume_size}"
      RELAYS_MIN                               = "${var.node_group_relays_min}"
      RELAYS_MAX                               = "${var.node_group_relays_max}"
      RELAY_INSTANCE_TYPE                      = "${var.node_group_relays_droplet_size}"
      RELAY_VOLUME_SIZE                        = "${var.node_group_relays_volume_size}"
      PATH_TO_JSON_TEMPLATES                   = "${abspath(path.module)}/red5pro-installer/nodegroup-json-templates"
      NODE_ROUND_TRIP_AUTH_ENABLE              = "${var.node_config_round_trip_auth.enable}"
      NODE_ROUNT_TRIP_AUTH_TARGET_NODES        = "${join(",", var.node_config_round_trip_auth.target_nodes)}"
      NODE_ROUND_TRIP_AUTH_HOST                = "${var.node_config_round_trip_auth.auth_host}"
      NODE_ROUND_TRIP_AUTH_PORT                = "${var.node_config_round_trip_auth.auth_port}"
      NODE_ROUND_TRIP_AUTH_PROTOCOL            = "${var.node_config_round_trip_auth.auth_protocol}"
      NODE_ROUND_TRIP_AUTH_ENDPOINT_VALIDATE   = "${var.node_config_round_trip_auth.auth_endpoint_validate}"
      NODE_ROUND_TRIP_AUTH_ENDPOINT_INVALIDATE = "${var.node_config_round_trip_auth.auth_endpoint_invalidate}"
      NODE_WEBHOOK_ENABLE                      = "${var.node_config_webhooks.enable}"
      NODE_WEBHOOK_TARGET_NODES                = "${join(",", var.node_config_webhooks.target_nodes)}"
      NODE_WEBHOOK_ENDPOINT                    = "${var.node_config_webhooks.webhook_endpoint}"
      NODE_SOCIAL_PUSHER_ENABLE                = "${var.node_config_social_pusher.enable}"
      NODE_SOCIAL_PUSHER_TARGET_NODES          = "${join(",", var.node_config_social_pusher.target_nodes)}"
      NODE_RESTREAMER_ENABLE                   = "${var.node_config_restreamer.enable}"
      NODE_RESTREAMER_TARGET_NODES             = "${join(",", var.node_config_restreamer.target_nodes)}"
      NODE_RESTREAMER_TSINGEST                 = "${var.node_config_restreamer.restreamer_tsingest}"
      NODE_RESTREAMER_IPCAM                    = "${var.node_config_restreamer.restreamer_ipcam}"
      NODE_RESTREAMER_WHIP                     = "${var.node_config_restreamer.restreamer_whip}"
      NODE_RESTREAMER_SRTINGEST                = "${var.node_config_restreamer.restreamer_srtingest}"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${abspath(path.module)}/red5pro-installer/r5p_delete_node_group.sh '${self.triggers.SM_IP}' '${self.triggers.R5AS_AUTH_USER}' '${self.triggers.R5AS_AUTH_PASS}'"
  }

  depends_on = [time_sleep.wait_for_delete_nodegroup[0]]

  lifecycle {
    precondition {
      condition     = var.node_image_create == true
      error_message = "ERROR! Node group creation requires the creation of a Node image for the node group. Please set the 'node_image_create' variable to 'true' and re-run the Terraform apply."
    }
  }
}