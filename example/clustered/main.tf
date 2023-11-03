#################################################
# Example for single Red5 Pro server deployment #
#################################################
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.0"
    }
  }
}

provider "digitalocean" {
  token                     = ""                                                            # Digital Ocean token
}

module "red5pro_cluster" {
  source                    = "../../"
  digital_ocean_token       = ""                                                             # Digital Ocean token
  digital_ocean_region      = ""                                                             # Digital Ocean region where resources will create eg: blr1
  type                      = "cluster"                                                      # Deployment type: single, cluster, autoscaling
  name                      = ""                                                             # Name to be used on all the resources as identifier
  digital_ocean_project     = true                                                           # Create a new project in Digital Ocean
  project_name              = "Example-Project"                                              # New Project name in digital Ocean
  ubuntu_version            = "20.04"                                                        # The version of ubuntu which is used to create droplet, it can either be 20.04 or 22.04

  path_to_red5pro_build                    = "./red5pro-server-0.0.0.0-release.zip"          # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_terraform_cloud_controller       = "./terraform-cloud-controller-0.0.0.jar"        # Absolute path or relative path to terraform cloud controller jar file
  path_to_terraform_service_build          = "./terraform-service-0.0.0.zip"                 # Absolute path or relative path to terraform service ZIP file

  # SSH key configuration
  ssh_key_create            = false                                                          # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key"                                                  # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "./example.pem"                                                # Path to existing SSH private key
  
  # VPC configuration
  vpc_create                = true                                                           # true - create new VPC, false - use existing VPC
  vpc_name_existing         = "example-vpc"                                                  # VPC name of existing VPC if vpc_create is false

  # Database Configuration
  mysql_database_create     = true                                                           # true - create a new database false- Install locally
  mysql_database_size       = "db-s-1vcpu-2gb"                                               # New database size
  mysql_username            = "example-user"                                                 # Username for locally install databse
  mysql_password            = "example-password"                                             # Password for locally install databse
  mysql_port                = "25060"                                                        # Port for locally install databse

  # Stream Manager Configuration
  stream_manager_droplet_size = "c-4"                                                        # Stream Manager droplet size
  stream_manager_api_key      = ""                                                           # Stream Manager api key

  # Terraform Service configuration
  dedicated_terra_host_create = true                                                         # true- Create a dedicate terraform service droplet   false - install locally on stream manager
  terra_api_token             = ""                                                           # Terraform api token
  terra_parallelism           = "20"                       
  terraform_service_droplet_size = "c-4"                                                     # Terraform droplet size if dedicated terra host create is true

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
  
  red5pro_inspector_enable                      = false                                      # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)
  red5pro_restreamer_enable                     = false                                      # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/)
  red5pro_socialpusher_enable                   = false                                      # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/)
  red5pro_suppressor_enable                     = false                                      # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  red5pro_hls_enable                            = false                                      # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/)
  red5pro_round_trip_auth_enable                = false                                      # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)
  red5pro_round_trip_auth_host                  = "round-trip-auth.example.com"              # Round trip authentication server host
  red5pro_round_trip_auth_port                  = 3000                                       # Round trip authentication server port
  red5pro_round_trip_auth_protocol              = "http"                                     # Round trip authentication server protocol
  red5pro_round_trip_auth_endpoint_validate     = "/validateCredentials"                     # Round trip authentication server endpoint for validate
  red5pro_round_trip_auth_endpoint_invalidate   = "/invalidateCredentials"                   # Round trip authentication server endpoint for invalidate

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

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create = true                                                                 # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_name   = "example-node-group"                                                 # Node group name
  # Origin node configuration
  node_group_origins               = 1                                                     # Number of Origins
  node_group_origins_droplet_type = "c-4"                                                  # Origins DO droplet 
  node_group_origins_capacity      = 30                                                    # Connections capacity for Origins
  # Edge node configuration
  node_group_edges               = 0                                                       # Number of Edges
  node_group_edges_droplet_type = "c-4"                                                    # Edges DO droplet 
  node_group_edges_capacity      = 300                                                     # Connections capacity for Edges
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
  value = module.red5pro_cluster
}