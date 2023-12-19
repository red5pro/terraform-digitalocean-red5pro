variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
  validation {
    condition     = length(var.name) > 0
    error_message = "The name value must be a valid! Example: example-name"
  }
}

variable "digital_ocean_project" {
  description = "Create a new project in Digital Ocean to access all created resources. true = create new project, false = use default project in DO."
  default = true
}

variable "project_name" {
  description = "A unique project used in digital ocean to create all resources. When do_project = true"
  type = string
  default = ""
}

variable "type" {
  description = "Type of deployment: single, cluster, autoscaling"
  type        = string
  default     = "single"
  validation {
    condition     = var.type == "single" || var.type == "cluster" || var.type == "autoscaling"
    error_message = "The type value must be a valid! Example: single, cluster, autoscaling"
  }
}
variable "ubuntu_version" {
  description = "Ubuntu version which is going to be used for creating droplet in Digital Ocean"
  type = string
  default = "20.04"
  validation {
    condition = var.ubuntu_version == "20.04" || var.ubuntu_version == "22.04"
    error_message = "Please specify the correct ubuntu version, it can either be 20.04 or 22.04"
  }
}

variable "path_to_red5pro_build" {
  description = "Path to the Red5 Pro build zip file, absolute path or relative path. https://account.red5pro.com/downloads. Example: /home/ubuntu/red5pro-server-0.0.0.b0-release.zip"
  type        = string
  default     = ""
  validation {
    condition     = fileexists(var.path_to_red5pro_build) == true
    error_message = "The path_to_red5pro_build value must be a valid! Example: /home/ubuntu/red5pro-server-0.0.0.b0-release.zip"
  }
}

# Digital Ocean configuration
variable "digital_ocean_region" {
  description = "DO region to deploy the resources"
  default     = ""
}

variable "digital_ocean_token" {
  description = "DO token to access the services of cloud"
  default     = ""
}

# VPC configuration
variable "vpc_cidr_block" {
  description = "Digital Ocean VPC IP range for Red5 Pro"
  type        = string
  default     = "10.5.0.0/16"
}
variable "vpc_create" {
  description = "Create a new VPC or use an existing one. true = create new, false = use existing"
  type        = bool
  default     = true
}
variable "vpc_name_existing" {
  description = "VPC NAME which is used to configure the droplet."
  type        = string
  default     = ""
}

# Red5 Pro Terraform Service properties
variable "dedicated_terraform_service_host_create" {
  description = "Create a dedicated DO droplet for Red5 pro Terraform Service "
  type        = bool
  default     = true
}
variable "terraform_service_api_token" {
  description = "API Token for Teraform Service to autherize the APIs"
  type        = string
  default     = ""
}
variable "terraform_service_parallelism" {
  description = "Number of Terraform concurrent operations and used for non-standard rate limiting"
  type        = string
  default     = "20"
}
variable "terraform_service_droplet_size" {
  description = "Red5 Pro Stream Manager server droplet size"
  type        = string
  default     = "s-1vcpu-1gb"
}

# Digital Ocean Firewall Configuration to allow required ports of red5pro stream manager droplet
# Inbound rules for stream manager red5pro
variable "firewall_stream_manager_inbound" {
  description = "List of inbound firewall rules"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "5080"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "8083"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}
# Outbound rules for stream manager red5pro
variable "firewall_stream_manager_outbound" {
  description = "List of outbound firewall rules"
  type = list(object({
    protocol              = string
    port_range            = string
    destination_addresses = list(string)
  }))
  default = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "icmp"
      port_range            = "0"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

# Inbound rules for terraform service
variable "firewall_terraform_service_inbound" {
  description = "List of inbound firewall rules"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "8083"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}
# Outbound rules for terraform service
variable "firewall_terraform_service_outbound" {
  description = "List of outbound firewall rules"
  type = list(object({
    protocol              = string
    port_range            = string
    destination_addresses = list(string)
  }))
  default = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "icmp"
      port_range            = "0"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

# Digital Ocean Firewall Configuration to allow required ports of red5pro single droplet
variable "inbound_rules" {
  description = "List of inbound firewall rules"
  type = list(object({
    protocol         = string
    port_range       = string
    source_addresses = list(string)
  }))
  default = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "5080"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "1935"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "8554"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "udp"
      port_range       = "8000-8001"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "udp"
      port_range       = "40000-65535"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

variable "outbound_rules" {
  description = "List of outbound firewall rules"
  type = list(object({
    protocol              = string
    port_range            = string
    destination_addresses = list(string)
  }))
  default = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "icmp"
      port_range            = "0"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

# Load Balancer Configuration
variable "lb_size" {
  description = " The size of the Load Balancer.  It must be either lb-small, lb-medium, or lb-large."
  type = string
  default = ""
}

variable "lb_ssl_create" {
  description = "Create a new SSL certificate for Load Balancer created in DO (autoscaling)"
  type = bool
  default = true
}

variable "lb_ssl_certificate_type" {
  description = "Type of certificate to create SSL for Load Balancer in Digital Ocean(custom or lets_encrypt)"
  type        = string
  default     = "custom"
  validation {
    condition     = var.lb_ssl_certificate_type == "custom" || var.lb_ssl_certificate_type == "lets_encrypt"
    error_message = "The type value must be a valid! Example: custom or lets_encrypt"
  }
}

variable "existing_lb_domain_name" {
  description = "If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = lets_encrypt, Load balancer exiting fully qualified domain names (FQDNs) for which the certificate will be issued. Only when 'lb_ssl_certificate_type' == lets_encrypt"
  type = string
  default = ""
}

variable "lb_exist_ssl_cert_name" {
   description = "If 'lb_ssl_create' = false, Use existing SSL certificate for Load Balancer already uploaded in DO (autoscaling)"
   type = string
   default = ""
}

variable "new_lb_cert_name" {
  description = "If 'lb_ssl_create' = true, New Load Balancer certificate name"
  type = string
  default = ""
}

variable "cert_fullchain" {
  description = "If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = custom, File path for SSL/TLS CA Certificate Fullchain (autoscaling)"
  type        = string
  default     = ""
}

variable "cert_private_key" {
  description = "If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = custom, File path for SSL/TLS Certificate Private Key (autoscaling)"
  type        = string
  default     = ""
}

variable "leaf_public_cert" {
  description = "If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = custom, File path for SSL/TLS Certificate Public Cert (autoscaling)"
  type        = string
  default     = ""
}

# MySQL configuration
variable "mysql_database_create" {
  description = "Create a new MySQL Database"
  type        = bool
  default     = false
}
variable "mysql_database_size" {
  description = "MySQL database size"
  type        = string
  default     = "db-s-1vcpu-2gb"
}
variable "mysql_username" {
  description = "MySQL user name if mysql_database_create = false"
  type        = string
  default     = ""
}
variable "mysql_password" {
  description = "MySQL password if mysql_database_create = false"
  type        = string
  default     = ""
  sensitive = true
  # validation {
  #   condition = length(var.mysql_password) >= 8
  #   error_message = "Password must have at least 8 characters."
  # }
  # validation {
  #   condition = can(regex("[A-Z]", var.mysql_password))
  #   error_message = "Password must contain at least one uppercase letter."
  # }
  # validation {
  #   condition = can(regex("[a-z]", var.mysql_password))
  #   error_message = "Password must contain at least one lowercase letter."
  # }
  # validation {
  #   condition = can(regex("[^a-zA-Z0-9]", var.mysql_password))
  #   error_message = "Password must contain at least one character that isn't a letter or a digit."
  # }
  # validation {
  #   condition = can(regex("[0-9]", var.mysql_password))
  #   error_message = "Password must contain at least one digit."
  # }
}
variable "mysql_port" {
  description = "MySQL port if mysql_database_create = false"
  type        = number
  default     = 25060
}


# SSH key configuration
variable "ssh_key_create" {
  description = "Create a new SSH key pair or use an existing one. true = create new, false = use existing"
  type        = bool
  default     = true
}
variable "ssh_key_name" {
  description = "SSH key pair name new/existing"
  type        = string
  default     = ""
}
variable "ssh_private_key_path" {
  description = "SSH private key path existing"
  type        = string
  default     = ""
}

# Stream Manager Configuration
variable "autoscale_stream_manager_count" {
  description = "Total number stream manager required to setup in autoscale."
  type        = number
  default     = 2
  validation {
    condition     = var.autoscale_stream_manager_count >= 2
    error_message = "The stream manager count should be greater than or equal to '2'. The default count is '2'."
  }
}
variable "stream_manager_droplet_size" {
  description = "Red5 Pro Stream Manager server droplet size"
  type        = string
  default     = "c-4"
}

variable "stream_manager_api_key" {
  description = "API Key for Red5Pro Stream Manager"
  type        = string
  default     = ""

}

variable "red5pro_cluster_key" {
  description = "Red5Pro Cluster Key"
  type        = string
  default     = ""
}

# Red5 Pro single server configuration
variable "single_droplet_size" {
  description = "Red5 Pro Single server droplet size"
  type        = string
  default     = "c-4"
}
variable "red5pro_license_key" {
  description = "Red5 Pro license key (https://www.red5pro.com/docs/installation/installation/license-key/)"
  type        = string
  default     = ""
}
variable "red5pro_api_enable" {
  description = "Red5 Pro Server API enable/disable (https://www.red5pro.com/docs/development/api/overview/)"
  type        = bool
  default     = true
}
variable "red5pro_api_key" {
  description = "Red5 Pro server API key"
  type        = string
  default     = ""
}
variable "red5pro_inspector_enable" {
  description = "Red5 Pro Single server Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_restreamer_enable" {
  description = "Red5 Pro Single server Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_socialpusher_enable" {
  description = "Red5 Pro Single server SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "red5pro_suppressor_enable" {
  description = "Red5 Pro Single server Suppressor enable"
  type        = bool
  default     = false
}
variable "red5pro_hls_enable" {
  description = "Red5 Pro Single server HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_enable" {
  description = "Round trip authentication on the red5pro server enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "red5pro_round_trip_auth_host" {
  description = "Round trip authentication server host"
  type        = string
  default     = ""
}
variable "red5pro_round_trip_auth_port" {
  description = "Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "red5pro_round_trip_auth_protocol" {
  description = "Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "red5pro_round_trip_auth_endpoint_validate" {
  description = "Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# HTTPS/SSL variables for single/cluster
variable "https_letsencrypt_enable" {
  description = "Enable HTTPS and get SSL certificate using Let's Encrypt automaticaly (single/cluster/autoscale) (https://www.red5pro.com/docs/installation/ssl/overview/)"
  type        = bool
  default     = false
}
variable "https_letsencrypt_certificate_domain_name" {
  description = "Domain name for Let's Encrypt ssl certificate (single/cluster/autoscale)"
  type        = string
  default     = ""
}
variable "https_letsencrypt_certificate_email" {
  description = "Email for Let's Encrypt ssl certificate (single/cluster/autoscale)"
  type        = string
  default     = ""
}
variable "https_letsencrypt_certificate_password" {
  description = "Password for Let's Encrypt ssl certificate (single/cluster/autoscale)"
  type        = string
  default     = ""
}

variable "path_to_terraform_cloud_controller" {
  description = "Path to the Terraform Cloud Controller jar file, absolute path or relative path. https://account.red5pro.com/downloads. Example: /home/ubuntu/terraform-do-red5pro/terraform-cloud-controller-0.0.0.jar"
  type        = string
  default     = ""
}

variable "path_to_terraform_service_build" {
  description = "Path to the Terraform Service build zip file, absolute path or relative path. https://account.red5pro.com/downloads. Example: /home/ubuntu/terraform-do-red5pro/terraform-service-0.0.0.zip"
  type        = string
  default     = ""
}

########################################################
# Red5 Pro autoscaling Origin node image configuration
########################################################
variable "origin_image_create" {
  description = "Create new Origin node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "origin_image_droplet_size" {
  description = "Origin node image - droplet size"
  type        = string
  default     = "c-4"
}
variable "origin_image_red5pro_inspector_enable" {
  description = "Origin node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_restreamer_enable" {
  description = "Origin node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_socialpusher_enable" {
  description = "Origin node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_suppressor_enable" {
  description = "Origin node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_hls_enable" {
  description = "Origin node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_enable" {
  description = "Origin node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "origin_image_red5pro_round_trip_auth_host" {
  description = "Origin node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "origin_image_red5pro_round_trip_auth_port" {
  description = "Origin node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "origin_image_red5pro_round_trip_auth_protocol" {
  description = "Origin node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "origin_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Origin node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "origin_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Origin node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Edge node image configuration
variable "edge_image_create" {
  description = "Create new Edge node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "edge_image_droplet_size" {
  description = "Edge node image - droplet_size"
  type        = string
  default     = "c-4"
}
variable "edge_image_red5pro_inspector_enable" {
  description = "Edge node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_restreamer_enable" {
  description = "Edge node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_socialpusher_enable" {
  description = "Edge node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_suppressor_enable" {
  description = "Edge node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_hls_enable" {
  description = "Edge node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_enable" {
  description = "Edge node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "edge_image_red5pro_round_trip_auth_host" {
  description = "Edge node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "edge_image_red5pro_round_trip_auth_port" {
  description = "Edge node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "edge_image_red5pro_round_trip_auth_protocol" {
  description = "Edge node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Edge node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "edge_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Edge node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Transcoder node image configuration
variable "transcoder_image_create" {
  description = "Create new Transcoder node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "transcoder_image_droplet_size" {
  description = "Transcoder node image - droplet_size"
  type        = string
  default     = "c-4"
}
variable "transcoder_image_red5pro_inspector_enable" {
  description = "Transcoder node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_restreamer_enable" {
  description = "Transcoder node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_socialpusher_enable" {
  description = "Transcoder node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_suppressor_enable" {
  description = "Transcoder node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_hls_enable" {
  description = "Transcoder node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_enable" {
  description = "Transcoder node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "transcoder_image_red5pro_round_trip_auth_host" {
  description = "Transcoder node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "transcoder_image_red5pro_round_trip_auth_port" {
  description = "Transcoder node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "transcoder_image_red5pro_round_trip_auth_protocol" {
  description = "Transcoder node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Transcoder node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "transcoder_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Transcoder node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro Relay node image configuration
variable "relay_image_create" {
  description = "Create new Relay node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "relay_image_droplet_size" {
  description = "Relay node image - droplet size"
  type        = string
  default     = "c-4"
}
variable "relay_image_red5pro_inspector_enable" {
  description = "Relay node image - Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_restreamer_enable" {
  description = "Relay node image - Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_socialpusher_enable" {
  description = "Relay node image - SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_suppressor_enable" {
  description = "Relay node image - Suppressor enable/disable"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_hls_enable" {
  description = "Relay node image - HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_enable" {
  description = "Relay node image - Round trip authentication on the enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "relay_image_red5pro_round_trip_auth_host" {
  description = "Relay node image - Round trip authentication server host"
  type        = string
  default     = ""
}
variable "relay_image_red5pro_round_trip_auth_port" {
  description = "Relay node image - Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "relay_image_red5pro_round_trip_auth_protocol" {
  description = "Relay node image - Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_validate" {
  description = "Relay node image - Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "relay_image_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Relay node image - Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

# Red5 Pro autoscaling Node group - (Optional) 
variable "node_group_create" {
  description = "Create new node group. Linux or Mac OS only."
  type        = bool
  default     = false
}
variable "node_group_name" {
  description = "Node group name"
  type        = string
  default     = ""
}
variable "node_group_origins" {
  description = "Number of Origins"
  type        = number
  default     = 1
}
variable "node_group_origins_droplet_type" {
  description = "Droplet type for Origins"
  type        = string
  default     = "c-4"
}
variable "node_group_origins_capacity" {
  description = "Connections capacity for Origins"
  type        = number
  default     = 30
}
variable "node_group_edges" {
  description = "Number of Edges"
  type        = number
  default     = 1
}
variable "node_group_edges_droplet_type" {
  description = "Droplet type for Edges"
  type        = string
  default     = "c-4"
}
variable "node_group_edges_capacity" {
  description = "Connections capacity for Edges"
  type        = number
  default     = 300
}
variable "node_group_transcoders" {
  description = "Number of Transcoders"
  type        = number
  default     = 1
}
variable "node_group_transcoders_droplet_type" {
  description = "Droplet type for Transcoders"
  type        = string
  default     = "c-4"
}
variable "node_group_transcoders_capacity" {
  description = "Connections capacity for Transcoders"
  type        = number
  default     = 30
}
variable "node_group_relays" {
  description = "Number of Relays"
  type        = number
  default     = 1
}
variable "node_group_relays_droplet_type" {
  description = "Droplet type for Relays"
  type        = string
  default     = "c-4"
}
variable "node_group_relays_capacity" {
  description = "Connections capacity for Relays"
  type        = number
  default     = 30
}


# Video on demand using Cloud Storage
variable "red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)"
  type        = bool
  default     = false
}
variable "red5pro_cloudstorage_digitalocean_spaces_access_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_digitalocean_spaces_secret_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_digitalocean_spaces_name" {
  description = "Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_digitalocean_spaces_region" {
  description = "Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces)"
  type        = string
  default     = ""
}
variable "red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
variable "origin_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)"
  type        = bool
  default     = false
}
variable "origin_red5pro_cloudstorage_digitalocean_spaces_access_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)"
  type        = string
  default     = ""
}
variable "origin_red5pro_cloudstorage_digitalocean_spaces_secret_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)"
  type        = string
  default     = ""
}
variable "origin_red5pro_cloudstorage_digitalocean_spaces_name" {
  description = "Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)"
  type        = string
  default     = ""
}
variable "origin_red5pro_cloudstorage_digitalocean_spaces_region" {
  description = "Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces)"
  type        = string
  default     = ""
}
variable "origin_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

variable "edge_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)"
  type        = bool
  default     = false
}
variable "edge_red5pro_cloudstorage_digitalocean_spaces_access_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)"
  type        = string
  default     = ""
}
variable "edge_red5pro_cloudstorage_digitalocean_spaces_secret_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)"
  type        = string
  default     = ""
}
variable "edge_red5pro_cloudstorage_digitalocean_spaces_name" {
  description = "Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)"
  type        = string
  default     = ""
}
variable "edge_red5pro_cloudstorage_digitalocean_spaces_region" {
  description = "Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces)"
  type        = string
  default     = ""
}
variable "edge_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
variable "transcoder_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)"
  type        = bool
  default     = false
}
variable "transcoder_red5pro_cloudstorage_digitalocean_spaces_access_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)"
  type        = string
  default     = ""
}
variable "transcoder_red5pro_cloudstorage_digitalocean_spaces_secret_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)"
  type        = string
  default     = ""
}
variable "transcoder_red5pro_cloudstorage_digitalocean_spaces_name" {
  description = "Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)"
  type        = string
  default     = ""
}
variable "transcoder_red5pro_cloudstorage_digitalocean_spaces_region" {
  description = "Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces)"
  type        = string
  default     = ""
}
variable "transcoder_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}

variable "relay_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)"
  type        = bool
  default     = false
}
variable "relay_red5pro_cloudstorage_digitalocean_spaces_access_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)"
  type        = string
  default     = ""
}
variable "relay_red5pro_cloudstorage_digitalocean_spaces_secret_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)"
  type        = string
  default     = ""
}
variable "relay_red5pro_cloudstorage_digitalocean_spaces_name" {
  description = "Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)"
  type        = string
  default     = ""
}
variable "relay_red5pro_cloudstorage_digitalocean_spaces_region" {
  description = "Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces)"
  type        = string
  default     = ""
}
variable "relay_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}