#################################################
# Example for autoscaling Red5 Pro server deployment #
#################################################
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">=2.34.0"
    }
  }
}

provider "digitalocean" {
  token                     = ""                                                           # Digital Ocean token (https://cloud.digitalocean.com/account/api/tokens)
}

module "red5pro_autoscale" {
  source                    = "../../"
  digital_ocean_token       = ""                                                            # Digital Ocean token (https://cloud.digitalocean.com/account/api/tokens)
  digital_ocean_region      = "blr1"                                                        # Digital Ocean region where resources will create eg: blr1
  type                      = "autoscaling"                                                 # Deployment type: single, cluster, autoscaling
  name                      = ""                                                            # Name to be used on all the resources as identifier
  digital_ocean_project     = true                                                          # Create a new project in Digital Ocean
  project_name              = "Example-Project"                                             # New Project name in digital Ocean
  ubuntu_version            = "20.04"                                                       # The version of ubuntu which is used to create droplet, it can either be 20.04 or 22.04

  path_to_red5pro_build     = "./red5pro-server-0.0.0.0-release.zip"                        # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_terraform_cloud_controller = "./terraform-cloud-controller-0.0.0.jar"             # Absolute path or relative path to terraform cloud controller jar file
  path_to_terraform_service_build = "./terraform-service-0.0.0.zip"                         # Absolute path or relative path to terraform service ZIP file

  # SSH key configuration
  ssh_key_create            = true                                                          # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key"                                                 # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "./example_key.pem"                                           # Path to existing SSH private key
  
  # VPC configuration
  vpc_cidr_block            = "10.5.0.0/16"                                                 # VPC CIDR value for Digital Ocean
  vpc_create                = true                                                          # true - create new VPC, false - use existing VPC
  vpc_name_existing         = "example-vpc"                                                 # VPC name of existing VPC if vpc_create is false

  # Stream Manager Configuration
  autoscale_stream_manager_count = 2                                                        # Total number stream manager required to setup in autoscale.
  stream_manager_droplet_size = "c-4"                                                       # Stream Manager droplet size
  stream_manager_api_key      = ""                                                          # Stream Manager api key

  # Database Configuration
  mysql_database_size       = "db-s-1vcpu-2gb"                                              # New MysQL database size

  # Terraform Service configuration
  terraform_service_api_token             = ""                                                       # Terraform api token
  terraform_service_parallelism           = "20"                                                     # Terraform parallelism
  terraform_service_droplet_size          = "c-4"                                                    # Terraform droplet size 

  # Load Balancer configuration for Stream Manager
  lb_ssl_create               = false                                                        # Create a new SSL certificate for Load Balancer created in DO (autoscaling)
  lb_size                     = "lb-small"                                                   # The size of the Load Balancer. It must be either lb-small, lb-medium, or lb-large
  cert_fullchain              = "./fullchain.pem"                                    # Only If 'lb_ssl_create' = true  File path for SSL/TLS CA Certificate Fullchain (autoscaling)
  cert_private_key            = "./privkey.pem"                                      # Only If 'lb_ssl_create' = true  File path for SSL/TLS Certificate Private Key (autoscaling)
  leaf_public_cert            = "./cert.pem"                                         # Only If 'lb_ssl_create' = true  File path for SSL/TLS Certificate Public Cert (autoscaling)

  # Red5 Pro general configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key                           = ""                                         # Red5 Pro cluster key
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                               = ""                                         # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = false                                         # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"                         # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                                 # Password for Let's Encrypt SSL certificate

  # Red5 Pro autoscaling Origin node image configuration
  origin_image_create                                      = true                          # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  origin_image_droplet_size                                = "c-4"                         # droplet type for Origin node image
  origin_image_red5pro_inspector_enable                    = false                         # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)
  origin_image_red5pro_restreamer_enable                   = false                         # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/)
  origin_image_red5pro_socialpusher_enable                 = false                         # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/)
  origin_image_red5pro_suppressor_enable                   = false                         # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  origin_image_red5pro_hls_enable                          = false                         # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/)
  origin_image_red5pro_round_trip_auth_enable              = false                         # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)
  origin_image_red5pro_round_trip_auth_host                = "round-trip-auth.example.com" # Round trip authentication server host
  origin_image_red5pro_round_trip_auth_port                = 3000                          # Round trip authentication server port
  origin_image_red5pro_round_trip_auth_protocol            = "http"                        # Round trip authentication server protocol
  origin_image_red5pro_round_trip_auth_endpoint_validate   = "/validateCredentials"        # Round trip authentication server endpoint for validate
  origin_image_red5pro_round_trip_auth_endpoint_invalidate = "/invalidateCredentials"      # Round trip authentication server endpoint for invalidate
  # Video on demand via Cloud Storage
  origin_red5pro_cloudstorage_enable                             = false                            # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)
  origin_red5pro_cloudstorage_digitalocean_spaces_access_key     = ""                               # Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)
  origin_red5pro_cloudstorage_digitalocean_spaces_secret_key     = ""                               # Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)
  origin_red5pro_cloudstorage_digitalocean_spaces_name           = "bucket-example-name"            # Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)
  origin_red5pro_cloudstorage_digitalocean_spaces_region         = "blr1"                           # Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces) (Valid locations are: ams3, fra1, nyc3, sfo3, sgp1)
  origin_red5pro_cloudstorage_postprocessor_enable               = true                             # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create = true                                                                 # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name   = "example-node-group"                                                 # Node group name
  # Origin node configuration
  node_group_origins               = 1                                                     # Number of Origins
  node_group_origins_droplet_type = "c-4"                                                  # Origins DO droplet 
  node_group_origins_capacity      = 30                                                    # Connections capacity for Origins
  # Edge node configuration
  node_group_edges               = 1                                                       # Number of Edges
  node_group_edges_droplet_type = "c-4"                                                    # Edges DO droplet 
  node_group_edges_capacity      = 30                                                     # Connections capacity for Edges
  # Transcoder node configuration
  node_group_transcoders               = 0                                                 # Number of Transcoders
  node_group_transcoders_droplet_type = "c-4"                                              # Transcoders DO droplet 
  node_group_transcoders_capacity      = 30                                                # Connections capacity for Transcoders
  # Relay node configuration
  node_group_relays               = 0                                                      # Number of Relays
  node_group_relays_droplet_type = "c-4"                                                   # Relays DO droplet 
  node_group_relays_capacity      = 30                                                     # Connections capacity for Relays

}

output "module_output" {
  sensitive = true
  value = module.red5pro_autoscale
}
