#################################################
# Example for Standalone Red5 Pro server deployment #
#################################################
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">=2.47.0"
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
  type                       = "standalone"                                                  # Deployment type: standalone, cluster, autoscaling
  name                       = "red5pro-standalone"                                          # Name to be used on all the resources as identifier

  # Red5 Pro artifacts configuration
  path_to_red5pro_build       = "./red5pro-server-0.0.0.0-release.zip"                       # Absolute path or relative path to Red5 Pro server ZIP file
  
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

  # Standalone Red5 Pro server Droplet configuration
  standalone_server_droplet_size                 = "c-2"                                     # Droplet size for Red5 Pro server in Digital Ocean
  standalone_server_reserved_ip_use_existing     = false                                     # True - Create the reserved IP for Standalone server, False - Use existing reserved IP for Standalone server
  standalone_server_existing_reserved_ip_address = "1.2.3.4"                                 # Already created reserved IP address for Standalone server

  # Red5Pro server configuration
  red5pro_license_key                           = "1111-2222-3333-4444"                      # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable                            = true                                       # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key                               = "examplekey"                               # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  standalone_red5pro_inspector_enable                      = false                                      # true - enable Red5 Pro server inspector, false - disable Red5 Pro server inspector (https://www.red5pro.com/docs/troubleshooting/inspector/overview/)
  standalone_red5pro_restreamer_enable                     = false                                      # true - enable Red5 Pro server restreamer, false - disable Red5 Pro server restreamer (https://www.red5pro.com/docs/special/restreamer/overview/)
  standalone_red5pro_socialpusher_enable                   = false                                      # true - enable Red5 Pro server socialpusher, false - disable Red5 Pro server socialpusher (https://www.red5pro.com/docs/special/social-media-plugin/overview/)
  standalone_red5pro_suppressor_enable                     = false                                      # true - enable Red5 Pro server suppressor, false - disable Red5 Pro server suppressor
  standalone_red5pro_hls_enable                            = false                                      # true - enable Red5 Pro server HLS, false - disable Red5 Pro server HLS (https://www.red5pro.com/docs/protocols/hls-plugin/hls-vod/)
  standalone_red5pro_round_trip_auth_enable                = false                                      # true - enable Red5 Pro server round trip authentication, false - disable Red5 Pro server round trip authentication (https://www.red5pro.com/docs/special/round-trip-auth/overview/)
  standalone_red5pro_round_trip_auth_host                  = "round-trip-auth.example.com"              # Round trip authentication server host
  standalone_red5pro_round_trip_auth_port                  = 3000                                       # Round trip authentication server port
  standalone_red5pro_round_trip_auth_protocol              = "http"                                     # Round trip authentication server protocol
  standalone_red5pro_round_trip_auth_endpoint_validate     = "/validateCredentials"                     # Round trip authentication server endpoint for validate
  standalone_red5pro_round_trip_auth_endpoint_invalidate   = "/invalidateCredentials"                   # Round trip authentication server endpoint for invalidate

  # Video on demand via Cloud Storage
  standalone_red5pro_cloudstorage_enable                             = false                            # Red5 Pro server cloud storage enable/disable (https://www.red5.net/docs/special/cloudstorage-plugin/digital-ocean-storage/)
  standalone_red5pro_cloudstorage_digitalocean_spaces_access_key     = ""                               # Red5 Pro server cloud storage - Digital Ocean space access key (DO Spaces)
  standalone_red5pro_cloudstorage_digitalocean_spaces_secret_key     = ""                               # Red5 Pro server cloud storage - Digital Ocean space secret key (DO Spaces)
  standalone_red5pro_cloudstorage_digitalocean_spaces_name           = "bucket-example-name"            # Red5 Pro server cloud storage - Digital Ocean space name (DO Spaces)
  standalone_red5pro_cloudstorage_digitalocean_spaces_region         = "nyc1"                           # Red5 Pro server cloud storage - Digital Ocean space region (DO Spaces) (Valid locations are: ams3, fra1, nyc3, sfo3, sgp1)
  standalone_red5pro_cloudstorage_postprocessor_enable               = false                            # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor (https://www.red5.net/docs/special/cloudstorage-plugin/server-configuration/)
  standalone_red5pro_cloudstorage_spaces_file_access                 = true                             # true - Cloud storage files private access only   false - Cloud storage files public access
  standalone_red5pro_cloudstorage_postprocessor_mp4_enable           = true                             # Red5 Pro server cloud storage - enable/disable Red5 Pro server postprocessor to convert flv to MP4 (https://www.red5.net/docs/protocols/converting/overview/)

  # Standalone Red5 Pro server HTTPS (SSL) certificate configuration
  https_ssl_certificate = "none" # none - do not use HTTPS/SSL certificate, letsencrypt - create new Let's Encrypt HTTPS/SSL certificate, imported - use existing HTTPS/SSL certificate

  # # Example of Let's Encrypt HTTPS/SSL certificate configuration - please uncomment and provide your domain name and email
  # https_ssl_certificate                       = "letsencrypt"
  # https_ssl_certificate_domain_name           = "red5pro.example.com"
  # https_ssl_certificate_email                 = "email@example.com"

  # # Example of imported HTTPS/SSL certificate configuration - please uncomment and provide your domain name, certificate and key paths
  # https_ssl_certificate                       = "imported"
  # https_ssl_certificate_domain_name           = "red5pro.example.com"
  # https_ssl_certificate_cert_path             = "/PATH/TO/SSL/CERT/fullchain.pem"
  # https_ssl_certificate_key_path              = "/PATH/TO/SSL/KEY/privkey.pem"

}

output "module_output" {
  sensitive = true
  value     = module.red5pro
}
