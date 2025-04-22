##################################################
# Example for cluster Red5 Pro server deployment #
##################################################
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">=2.34.0"
    }
  }
}

provider "digitalocean" {
  token                     = "dop_v1_example"                                               # Digital Ocean token (https://cloud.digitalocean.com/account/api/tokens)
}   

module "red5pro" {
  source                     = "../../"
  digital_ocean_region       = "nyc1"                                                        # Digital Ocean region where resources will create
  ubuntu_version             = "22.04"                                                       # The version of ubuntu which is used to create droplet, it can either be 20.04 or 22.04
  type                       = "cluster"                                                     # Deployment type: standalone, cluster, autoscale
  name                       = "red5pro-cluster"                                             # Name to be used on all the resources as identifier
  digital_ocean_access_token = "dop_v1_example"                                              # Digital Ocean access token (https://cloud.digitalocean.com/account/api/tokens)
  
  # Red5 Pro artifacts configuration
  path_to_red5pro_build              = "./red5pro-server-0.0.0.0-release.zip"                # Absolute path or relative path to Red5 Pro server ZIP file
 
  # SSH key configuration
  ssh_key_use_existing              = false                                                  # Use existing SSH key pair or create a new one. true = use existing, false = create new SSH key pair
  ssh_key_name_existing             = "example_key"                                          # SSH key name existing in Digital Ocean
  ssh_key_private_key_path_existing = "/PATH/TO/EXISTING/SSH/PRIVATE/KEY/example_key.pem"    # SSH private key path existing in local machine

  # Digital Ocean project configuration
  digital_ocean_project_use_existing  = false                                                # false - create a new project, true - use existing project
  digital_ocean_existing_project_name = "Exaple-Project-Name"                                # Existing Project name in digital Ocean

  # Digital Ocean VPC configuration
  vpc_use_existing            = false                                                        # Use existing VPC or create a new one. true = use existing, false = create new
  vpc_name_existing           = "example-vpc"                                                # VPC name of existing VPC if vpc_create is false

  # Stream Manager Configuration
  stream_manager_reserved_ip_use_existing     = false                                        # True - Create a reserved IP for Stream Manager, False - Use existing reserved IP for stream manager
  stream_manager_existing_reserved_ip_address = "1.2.3.4"                                    # Existing reserved IP for stream manager
  stream_manager_droplet_size                 = "c-4"                                        # Stream Manager droplet size
  stream_manager_auth_user                    = "example_user"                               # Stream Manager 2.0 authentication user name
  stream_manager_auth_password                = "example_password"                           # Stream Manager 2.0 authentication password
  stream_manager_proxy_user       = "example_proxy_user"                                     # Stream Manager 2.0 proxy user name
  stream_manager_proxy_password   = "example_proxy_password"                                 # Stream Manager 2.0 proxy password
  stream_manager_spatial_user     = "example_spatial_user"                                   # Stream Manager 2.0 spatial user name
  stream_manager_spatial_password = "example_spatial_password"                               # Stream Manager 2.0 spatial password
  stream_manager_version          = "latest"                                                 # Stream Manager 2.0 docker images version (latest, 14.1.0, 14.1.1, etc.) - https://hub.docker.com/r/red5pro/as-admin/tags

  # Terraform Service configuration
  kafka_standalone_instance_create = false                                                   # true - Create a dedicate terraform service droplet, false - install terraform service locally on the stream manager                                                   # Terraform service parallelism
  kafka_standalone_droplet_size    = "c-4"                                                   # Terraform service droplet size

  # Red5 Pro general configuration
  red5pro_license_key         = "1111-2222-3333-4444"                                        # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable          = true                                                         # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key             = "examplekey"                                                 # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Stream Manager 2.0 server HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate             = "letsencrypt"
  # https_ssl_certificate_domain_name = "red5pro.example.com"
  # https_ssl_certificate_email       = "email@example.com"

  # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate             = "imported"
  # https_ssl_certificate_domain_name = "red5pro.example.com"
  # https_ssl_certificate_cert_path   = "/PATH/TO/SSL/CERT/fullchain.pem"
  # https_ssl_certificate_key_path    = "/PATH/TO/SSL/KEY/privkey.pem"

  # Red5 Pro autoscaling Origin node image configuration
  node_image_create                                      = true                            # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  node_image_droplet_size                                = "c-2"                           # droplet type for Origin node image

# Extra configuration for Red5 Pro autoscaling nodes
  # Webhooks configuration - (Optional) https://www.red5.net/docs/special/webhooks/overview/
  node_config_webhooks = {
    enable           = false,
    target_nodes     = ["origin", "edge", "transcoder"],
    webhook_endpoint = "https://test.webhook.app/api/v1/broadcast/webhook"
  }
  # Round trip authentication configuration - (Optional) https://www.red5.net/docs/special/authplugin/simple-auth/
  node_config_round_trip_auth = {
    enable                   = false,
    target_nodes             = ["origin", "edge", "transcoder"],
    auth_host                = "round-trip-auth.example.com",
    auth_port                = 443,
    auth_protocol            = "https://",
    auth_endpoint_validate   = "/validateCredentials",
    auth_endpoint_invalidate = "/invalidateCredentials"
  }
  # Restreamer configuration - (Optional) https://www.red5.net/docs/special/restreamer/overview/
  node_config_restreamer = {
    enable               = false,
    target_nodes         = ["origin", "transcoder"],
    restreamer_tsingest  = true,
    restreamer_ipcam     = true,
    restreamer_whip      = true,
    restreamer_srtingest = true
  }
  # Social Pusher configuration - (Optional) https://www.red5.net/docs/development/social-media-plugin/rest-api/
  node_config_social_pusher = {
    enable       = false,
    target_nodes = ["origin", "edge", "transcoder"],
  }

  # Red5 Pro autoscaling Node group - (Optional)
  node_group_create                    = true                      # Linux or Mac OS only. true - create new Node group, false - not create new Node group
  node_group_origins_min               = 1                         # Number of minimum Origins
  node_group_origins_max               = 20                        # Number of maximum Origins
  node_group_origins_droplet_size      = "c-2"                     # Origins Instance Type
  node_group_origins_volume_size       = 50                        # Volume size in GB for Origins
  node_group_origins_connection_limit  = 20                        # Maximum number of publishers to the origin server
  node_group_edges_min                 = 1                         # Number of minimum Edges
  node_group_edges_max                 = 40                        # Number of maximum Edges
  node_group_edges_droplet_size        = "c-2"                     # Edges Instance Type
  node_group_edges_volume_size         = 50                        # Volume size in GB for Edges
  node_group_edges_connection_limit    = 200                       # Maximum number of subscribers to the edge server
  node_group_transcoders_min           = 0                         # Number of minimum Transcoders
  node_group_transcoders_max           = 20                        # Number of maximum Transcoders
  node_group_transcoders_droplet_size  = "c-2"                     # Transcoders Instance Type
  node_group_transcoders_volume_size   = 50                        # Volume size in GB for Transcoders
  node_group_transcoders_connection_limit = 20                     # Maximum number of publishers to the transcoder server
  node_group_relays_min                = 0                         # Number of minimum Relays
  node_group_relays_max                = 20                        # Number of maximum Relays
  node_group_relays_droplet_size       = "c-2"                     # Relays Instance Type
  node_group_relays_volume_size        = 50                        # Volume size in GB for Relays
}

output "module_output" {
  sensitive = true
  value     = module.red5pro
}