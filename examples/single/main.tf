#################################################
# Example for single Red5 Pro server deployment #
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
  token                     = "dop_v1_example"                                               # Digital Ocean token (https://cloud.digitalocean.com/account/api/tokens)
}

module "red5pro" {
  source                     = "../../"
  digital_ocean_region       = "nyc1"                                                        # Digital Ocean region where resources will create eg: blr1
  ubuntu_version             = "22.04"                                                       # The version of ubuntu which is used to create droplet, it can either be 20.04 or 22.04
  type                       = "single"                                                      # Deployment type: single, cluster, autoscaling
  name                       = "red5pro-single"                                              # Name to be used on all the resources as identifier
  
  # Red5 Pro artifacts configuration
  path_to_red5pro_build       = "./red5pro-server-0.0.0.0-release.zip"                       # Absolute path or relative path to Red5 Pro server ZIP file
  
  # SSH key configuration
  ssh_key_create              = true                                                         # true - create new SSH key, false - use existing SSH key
  ssh_key_name                = "example_key_name"                                           # Name for new SSH key or for existing SSH key
  ssh_private_key_path        = "./example_key.pem"                                          # Path to existing SSH private key

  # Digital Ocean project configuration
  project_create              = true                                                         # true - create a new project, false - use existing project
  project_name                = "Exaple-Project-Name"                                        # New Project name in digital Ocean

  # Digital Ocean VPC configuration
  vpc_create                  = true                                                         # true - create new VPC, false - use existing VPC
  vpc_cidr_block              = "10.5.0.0/16"                                                # VPC CIDR value for Digital Ocean
  vpc_name_existing           = "example-vpc"                                                # VPC name of existing VPC if vpc_create is false
  
  # Red5 Pro general configuration
  red5pro_license_key         = "1111-2222-3333-4444"                                        # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_cluster_key         = "examplekey"                                                 # Red5 Pro cluster key
  red5pro_api_enable          = true                                                         # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key             = "examplekey"                                                 # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = false                                         # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"                         # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                                 # Password for Let's Encrypt SSL certificate

  # Single Red5 Pro server Droplet configuration
  single_droplet_size                        = "c-2"                                         # Droplet size for Red5 Pro server in Digital Ocean

  # Red5Pro server configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                               = "examplekey"                               # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)
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
    
  # Video on demand via Cloud Storage
  red5pro_cloudstorage_enable                             = false                            # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)
  red5pro_cloudstorage_digitalocean_spaces_access_key     = ""                               # Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)
  red5pro_cloudstorage_digitalocean_spaces_secret_key     = ""                               # Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)
  red5pro_cloudstorage_digitalocean_spaces_name           = "bucket-example-name"            # Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)
  red5pro_cloudstorage_digitalocean_spaces_region         = "nyc1"                           # Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces) (Valid locations are: ams3, fra1, nyc3, sfo3, sgp1)
  red5pro_cloudstorage_postprocessor_enable               = false                            # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)
}

output "module_output" {
  sensitive = true
  value     = module.red5pro
}