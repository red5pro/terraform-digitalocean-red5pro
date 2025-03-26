variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
  validation {
    condition     = length(var.name) > 0
    error_message = "The name value must be a valid! Example: example-name"
  }
}

variable "digital_ocean_project_use_existing" {
  description = "Use existing project in Digital Ocean to access all created resources. true = use existing project in Digital Ocean, false = create new project."
  default = false
}

variable "digital_ocean_existing_project_name" {
  description = "Existing project name used in digital ocean to create all resources."
  type = string
  default = ""
}

variable "type" {
  description = "Type of deployment: standalone, cluster, autoscale"
  type        = string
  default     = "standalone"
  validation {
    condition     = var.type == "standalone" || var.type == "cluster" || var.type == "autoscale"
    error_message = "The type value must be a valid! Example: standalone, cluster, autoscale"
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
  description = "Digital Ocean region to deploy the resources"
  default     = ""
}

variable "digital_ocean_access_token" {
  description = "Digital Ocean token to access the services of cloud"
  default     = ""
}

# VPC configuration
variable "vpc_cidr_block" {
  description = "Digital Ocean VPC IP range for Red5 Pro"
  type        = string
  default     = "10.5.0.0/16"
}
variable "vpc_use_existing" {
  description = "Use existing VPC or create a new one. true = use existing, false = create new"
  type        = bool
  default     = true
}
variable "vpc_name_existing" {
  description = "Existing VPC name which is used to configure the droplet."
  type        = string
  default     = ""
}

variable "kafka_standalone_instance_create" {
  description = "Create a dedicated Digital Ocean droplet for Red5 pro Kafka"
  type        = bool
  default     = true
}
variable "kafka_standalone_droplet_size" {
  description = "Red5 Pro Kafka server droplet size"
  type        = string
  default     = "s-1vcpu-1gb"
}
variable "kafka_standalone_instance_arhive_url" {
  description = "Kafka standalone instance - archive URL"
  type        = string
  default     = "https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz"
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
      port_range       = "9092"
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

variable "firewall_kafka_standalone_inbound" {
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
      port_range       = "9092"
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  ]
}

variable "firewall_kafka_standalone_outbound" {
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

# Digital Ocean Firewall Configuration to allow required ports of red5pro Standalone droplet
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
variable "load_balancer_size" {
  description = " The size of the Load Balancer.  It must be either lb-small, lb-medium, or lb-large."
  type = string
  default = "lb-small"
  validation {
    condition     = var.load_balancer_size == "lb-small" || var.load_balancer_size == "lb-medium" || var.load_balancer_size == "lb-large"
    error_message = "The value must be a valid! Example: lb-small, lb-medium, lb-large"
  }
}

variable "create_load_balancer_with_ssl" {
  description = "Create a new SSL certificate for Load Balancer created in Digital Ocean (autoscale)"
  type = bool
  default = false
}

variable "load_balancer_cert_chain" {
  description = "If 'create_load_balancer_with_ssl' = true File path for SSL/TLS CA Certificate chain (autoscale)"
  type        = string
  default     = ""
}

variable "load_balancer_cert_private_key" {
  description = "If 'create_load_balancer_with_ssl' = true File path for SSL/TLS Certificate Private Key (autoscale)"
  type        = string
  default     = ""
}

variable "load_balancer_cert_public" {
  description = "If 'create_load_balancer_with_ssl' = true File path for SSL/TLS Certificate Public Cert (autoscale)"
  type        = string
  default     = ""
}
# SSH key configuration
variable "ssh_key_use_existing" {
  description = "Use existing SSH key pair or create a new one. true = use existing, false = create new"
  type        = bool
  default     = false
}
variable "ssh_key_name_existing" {
  description = "Existing SSH key pair name, already exist in Digital Ocean"
  type        = string
  default     = ""
}
variable "ssh_key_private_key_path_existing" {
  description = " Existing SSH private key path"
  type        = string
  default     = ""
}

# Stream Manager Configuration
variable "stream_managers_amount" {
  description = "Total number stream manager required to setup in autoscale."
  type        = number
  default     = 1
  validation {
    condition     = var.stream_managers_amount >= 1
    error_message = "The stream manager amount should be greater than or equal to '1'. The default count is '1'."
  }
}
variable "stream_manager_droplet_size" {
  description = "Red5 Pro Stream Manager server droplet size"
  type        = string
  default     = "c-4"
}

variable "stream_manager_auth_user" {
  description = "value to set the user name for Stream Manager 2.0 authentication"
  type        = string
  default     = ""
}
variable "stream_manager_auth_password" {
  description = "value to set the user password for Stream Manager 2.0 authentication"
  type        = string
  default     = ""
}

variable "stream_manager_reserved_ip_use_existing" {
  description = "Use existing Reserved IP for Stream Manager"
  type        = bool
  default     = false
}
variable "stream_manager_existing_reserved_ip_address" {
  description = "Existing reserved IP address for Stream Manager"
  type        = string
  default     = ""
}

# Red5 Pro Standalone server configuration
variable "standalone_server_droplet_size" {
  description = "Red5 Pro Standalone server droplet size"
  type        = string
  default     = "c-4"
}
variable "standalone_server_reserved_ip_use_existing" {
  description = "Use existing reserved IP for Standalone server"
  type        = bool
  default     = false
}
variable "standalone_server_existing_reserved_ip_address" {
  description = "Use already created reserved IP for Standalone server"
  type        = string
  default     = ""
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
variable "standalone_red5pro_inspector_enable" {
  description = "Red5 Pro Standalone server Inspector enable/disable (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_restreamer_enable" {
  description = "Red5 Pro Standalone server Restreamer enable/disable (https://www.red5pro.com/docs/special/restreamer/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_socialpusher_enable" {
  description = "Red5 Pro Standalone server SocialPusher enable/disable (https://www.red5pro.com/docs/special/social-media-plugin/rest-api/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_suppressor_enable" {
  description = "Red5 Pro Standalone server Suppressor enable"
  type        = bool
  default     = false
}
variable "standalone_red5pro_hls_enable" {
  description = "Red5 Pro Standalone server HLS enable/disable (https://www.red5pro.com/docs/protocols/hls-plugin/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_round_trip_auth_enable" {
  description = "Round trip authentication on the red5pro server enable/disable - Auth server should be deployed separately (https://www.red5pro.com/docs/special/round-trip-auth/overview/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_round_trip_auth_host" {
  description = "Round trip authentication server host"
  type        = string
  default     = ""
}
variable "standalone_red5pro_round_trip_auth_port" {
  description = "Round trip authentication server port"
  type        = number
  default     = 3000
}
variable "standalone_red5pro_round_trip_auth_protocol" {
  description = "Round trip authentication server protocol"
  type        = string
  default     = "http"
}
variable "standalone_red5pro_round_trip_auth_endpoint_validate" {
  description = "Round trip authentication server endpoint for validate"
  type        = string
  default     = "/validateCredentials"
}
variable "standalone_red5pro_round_trip_auth_endpoint_invalidate" {
  description = "Round trip authentication server endpoint for invalidate"
  type        = string
  default     = "/invalidateCredentials"
}

########################################################
# Red5 Pro autoscale node image configuration
########################################################
variable "node_image_create" {
  description = "Create new Node image true/false. (Default:true) (https://www.red5pro.com/docs/special/relays/overview/#origin-and-edge-nodes)"
  type        = bool
  default     = false
}
variable "node_image_droplet_size" {
  description = "Node image - droplet size"
  type        = string
  default     = "c-4"
}

# Red5 Pro autoscale Node group - (Optional) 
variable "node_group_create" {
  description = "Create new node group. Linux or Mac OS only."
  type        = bool
  default     = false
}
variable "node_group_name" {
  description = "Node group name"
  type        = string
  default     = "terraform-node-group"
}
variable "node_group_origins_min" {
  description = "Number of minimum Origins"
  type        = number
  default     = 1
}
variable "node_group_origins_max" {
  description = "Number of maximum Origins"
  type        = number
  default     = 20
}
variable "node_group_origins_droplet_size" {
  description = "Droplet size for Origins"
  type        = string
  default     = "c-4"
}
variable "node_group_origins_volume_size" {
  description = "Volume size in GB for Origin. Minimum 50GB"
  type        = number
  default     = 50
  validation {
    condition     = var.node_group_origins_volume_size >= 50
    error_message = "The node_group_origins_volume_size value must be a valid! Minimum 50"
  }
}
variable "node_group_edges_min" {
  description = "Number of minimum Edges"
  type        = number
  default     = 1
}
variable "node_group_edges_max" {
  description = "Number of maximum Edges"
  type        = number
  default     = 40
}
variable "node_group_edges_droplet_size" {
  description = "Droplet size for Edges"
  type        = string
  default     = "c-4"
}
variable "node_group_edges_volume_size" {
  description = "Volume size in GB for Edges. Minimum 50GB"
  type        = number
  default     = 50
  validation {
    condition     = var.node_group_edges_volume_size >= 50
    error_message = "The node_group_edges_volume_size value must be a valid! Minimum 50"
  }
}
variable "node_group_transcoders_min" {
  description = "Number of minimum Transcoders"
  type        = number
  default     = 1
}
variable "node_group_transcoders_max" {
  description = "Number of maximum Transcoders"
  type        = number
  default     = 20
}
variable "node_group_transcoders_droplet_size" {
  description = "Droplet size for Transcoders"
  type        = string
  default     = "c-4"
}
variable "node_group_transcoders_volume_size" {
  description = "Volume size in GB for Transcoder. Minimum 50GB"
  type        = number
  default     = 50
  validation {
    condition     = var.node_group_transcoders_volume_size >= 50
    error_message = "The node_group_transcoders_volume_size value must be a valid! Minimum 50"
  }
}
variable "node_group_relays_min" {
  description = "Number of minimum Relays"
  type        = number
  default     = 1
}
variable "node_group_relays_max" {
  description = "Number of maximum Relays"
  type        = number
  default     = 20
}
variable "node_group_relays_droplet_size" {
  description = "Droplet size for Relays"
  type        = string
  default     = "c-4"
}
variable "node_group_relays_volume_size" {
  description = "Volume size in GB for Relays. Minimum 50GB"
  type        = number
  default     = 50
  validation {
    condition     = var.node_group_relays_volume_size >= 50
    error_message = "The node_group_relays_volume_size value must be a valid! Minimum 50"
  }
}

# Video on demand using Cloud Storage
variable "standalone_red5pro_cloudstorage_enable" {
  description = "Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_cloudstorage_digitalocean_spaces_access_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space access key (Digital Ocean Spaces)"
  type        = string
  default     = ""
}
variable "standalone_red5pro_cloudstorage_digitalocean_spaces_secret_key" {
  description = "Red5 Pro server cloud storage - Digital Ocean space secret key (Digital Ocean Spaces)"
  type        = string
  default     = ""
}
variable "standalone_red5pro_cloudstorage_digitalocean_spaces_name" {
  description = "Red5 Pro server cloud storage - Digital Ocean space name (Digital Ocean Spaces)"
  type        = string
  default     = ""
}
variable "standalone_red5pro_cloudstorage_digitalocean_spaces_region" {
  description = "Red5 Pro server cloud storage - Digital Ocean space region (Digital Ocean Spaces)"
  type        = string
  default     = ""
}
variable "standalone_red5pro_cloudstorage_postprocessor_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)"
  type        = bool
  default     = false
}
variable "standalone_red5pro_cloudstorage_spaces_file_access" {
  description = "Red5 Pro server cloud storage files public access"
  type        = bool
  default     = false
}
variable "standalone_red5pro_cloudstorage_postprocessor_mp4_enable" {
  description = "Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor to convert flv to MP4 (https://www.red5.net/docs/protocols/converting/overview/)"
  type        = bool
  default     = false
}

variable "ubuntu_image_version" {
  type = map(string)
  default = {
    18.04 = "ubuntu-18-04-x64"
    20.04 = "ubuntu-20-04-x64"
    22.04 = "ubuntu-22-04-x64"
  }
}
variable "ubuntu_version" {
  description = "Ubuntu version which is going to be used for creating droplet in Digital Ocean"
  type        = string
  default     = "22.04"
  validation {
    condition = var.ubuntu_version == "18.04" || var.ubuntu_version == "20.04" || var.ubuntu_version == "22.04"
    error_message = "Please specify the correct ubuntu version, it can either be 18.04, 20.04 or 22.04"
  }
}

# HTTPS/SSL variables for standalone/cluster/autoscale
variable "https_ssl_certificate" {
  description = "Enable SSL (HTTPS) on the Standalone Red5 Pro server,  Stream Manager 2.0 server or Stream Manager 2.0 Load Balancer"
  type        = string
  default     = "none"
  validation {
    condition     = var.https_ssl_certificate == "none" || var.https_ssl_certificate == "letsencrypt" || var.https_ssl_certificate == "imported"
    error_message = "The https_ssl_certificate value must be a valid! Example: none, letsencrypt, imported"
  }
}
variable "https_ssl_certificate_domain_name" {
  description = "Domain name for SSL certificate (letsencrypt/imported)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_email" {
  description = "Email for SSL certificate (letsencrypt)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_cert_path" {
  description = "Path to SSL certificate (imported)"
  type        = string
  default     = ""
}
variable "https_ssl_certificate_key_path" {
  description = "Path to SSL key (imported)"
  type        = string
  default     = ""
}

# Extra configuration for Red5 Pro autoscaling nodes
variable "node_config_webhooks" {
  description = "Webhooks configuration - (Optional) https://www.red5.net/docs/special/webhooks/overview/"
  type = object({
    enable           = bool
    target_nodes     = list(string)
    webhook_endpoint = string
  })
  default = {
    enable           = false
    target_nodes     = []
    webhook_endpoint = ""
  }
}
variable "node_config_round_trip_auth" {
  description = "Round trip authentication configuration - (Optional) https://www.red5.net/docs/special/authplugin/simple-auth/"
  type = object({
    enable                   = bool
    target_nodes             = list(string)
    auth_host                = string
    auth_port                = number
    auth_protocol            = string
    auth_endpoint_validate   = string
    auth_endpoint_invalidate = string
  })
  default = {
    enable                   = false
    target_nodes             = []
    auth_host                = ""
    auth_port                = 443
    auth_protocol            = "https://"
    auth_endpoint_validate   = "/validateCredentials"
    auth_endpoint_invalidate = "/invalidateCredentials"
  }
}
variable "node_config_social_pusher" {
  description = "Social Pusher configuration - (Optional) https://www.red5.net/docs/development/social-media-plugin/rest-api/"
  type = object({
    enable       = bool
    target_nodes = list(string)
  })
  default = {
    enable       = false
    target_nodes = []
  }
}
variable "node_config_restreamer" {
  description = "Restreamer configuration - (Optional) https://www.red5.net/docs/special/restreamer/overview/"
  type = object({
    enable               = bool
    target_nodes         = list(string)
    restreamer_tsingest  = bool
    restreamer_ipcam     = bool
    restreamer_whip      = bool
    restreamer_srtingest = bool
  })
  default = {
    enable               = false
    target_nodes         = []
    restreamer_tsingest  = false
    restreamer_ipcam     = false
    restreamer_whip      = false
    restreamer_srtingest = false
  }
}