# Digital Ocean Red5 Pro Terraform module
[Red5 Pro](https://www.red5.net/) is a real-time video streaming server plaform known for its low-latency streaming capabilities, making it ideal for interactive applications like online gaming, streaming events and video conferencing etc.

This a reusable Terraform installer module for [Red5 Pro](https://www.red5pro.com/docs/installation/installation/do-install/) that provisions infrastucture over [Digital Ocean(DO)](https://www.digitalocean.com/).

## This module has 3 variants of Red5 Pro deployments

- **standalone** - Standalone Red5 Pro server
- **cluster** - Stream Manager 2.0 cluster with autoscaling nodes
- **autoscale** - Autoscaling Stream Managers 2.0 with autoscaling nodes

---

## Preparation

* Install **terraform** https://developer.hashicorp.com/terraform/downloads
  * Open your web browser and visit the [Terraform download page](https://developer.hashicorp.com/terraform/downloads), ensuring you get version 1.0.0 or higher. 
  * Download the suitable version for your operating system, 
  * Extract the compressed file, and then copy the Terraform binary to a location within your system's path
    * Configure path on Linux/macOS 
      * Open a terminal and type the following:

        ```$ sudo mv /path/to/terraform /usr/local/bin```
    * Configure path on Windows OS
      * Click 'Start', search for 'Control Panel', and open it.
      * Navigate to System > Advanced System Settings > Environment Variables.
      * Under System variables, find 'PATH' and click 'Edit'.
      * Click 'New' and paste the directory location where you extracted the terraform.exe file.
      * Confirm changes by clicking 'OK' and close all open windows.
      * Open a new terminal and verify that Terraform has been successfully installed.

* Install **Digital Ocean CLI** https://docs.digitalocean.com/reference/doctl/how-to/install/
* Install **jq** Linux or Mac OS only - `apt install jq` or `brew install jq` (It is using in bash scripts to create/delete Stream Manager node group using API)
* Download Red5 Pro server build: (Example: red5pro-server-0.0.0.b0-release.zip) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Get Digital Ocean API key or use existing (To access Digital Ocean Cloud) 
  * Follow the documentation for generating API keys - https://docs.digitalocean.com/reference/api/create-personal-access-token/
* Copy Red5 Pro server build to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
```

## Standalone Red5 Pro server deployment (standalone) - [Example](https://github.com/red5pro/terraform-digitalocean-red5pro/tree/master/examples/standalone)

### Terraform Deployed Resources (standalone)

- VPC
- Public subnet
- Firewall for Standalone Red5 Pro server
- SSH key pair (use existing or create a new one)
- Standalone Red5 Pro server instance
- SSL certificate for Standalone Red5 Pro server instance. Options:
  - `none` - Red5 Pro server without HTTPS and SSL certificate. Only HTTP on port `5080`
  - `letsencrypt` - Red5 Pro server with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `5080`, HTTPS on port `443`
  - `imported` - Red5 Pro server with HTTPS and imported SSL certificate. HTTP on port `5080`, HTTPS on port `443`

## Usage (standalone)

```hcl
provider "digitalocean" {
  token                     = "dop_v1_example"                                               # Digital Ocean token (https://cloud.digitalocean.com/account/api/tokens)
}

module "red5pro" {
  source                     = "../../"
  digital_ocean_region       = "nyc1"                                                        # Digital Ocean region where resources will create
  ubuntu_version             = "22.04"                                                       # The version of ubuntu which is used to create droplet, it can either be 20.04 or 22.04
  type                       = "standalone"                                                  # Deployment type: standalone, cluster, autoscale
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
```

---

## Red5 Pro Stream Manager cluster deployment (cluster) - [Example](https://github.com/red5pro/terraform-digitalocean-red5pro/tree/master/examples/cluster)

- VPC
- Public subnet
- Firewall for Stream Manager 2.0
- Firewall for Kafka
- Firewall for Red5 Pro (SM2.0) Autoscaling nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance (optional).
- Stream Manager 2.0 instance. Optionally include a Kafka server on the same instance.
- SSL certificate for Stream Manager 2.0 instance. Options:
  - `none` - Stream Manager 2.0 without HTTPS and SSL certificate. Only HTTP on port `80`
  - `letsencrypt` - Stream Manager 2.0 with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `80`, HTTPS on port `443`
  - `imported` - Stream Manager 2.0 with HTTPS and imported SSL certificate. HTTP on port `80`, HTTPS on port `443`
- Red5 Pro (SM2.0) node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

## Usage (cluster)

```hcl
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
  node_group_edges_min                 = 1                         # Number of minimum Edges
  node_group_edges_max                 = 40                        # Number of maximum Edges
  node_group_edges_droplet_size        = "c-2"                     # Edges Instance Type
  node_group_edges_volume_size         = 50                        # Volume size in GB for Edges
  node_group_transcoders_min           = 0                         # Number of minimum Transcoders
  node_group_transcoders_max           = 20                        # Number of maximum Transcoders
  node_group_transcoders_droplet_size  = "c-2"                     # Transcoders Instance Type
  node_group_transcoders_volume_size   = 50                        # Volume size in GB for Transcoders
  node_group_relays_min                = 0                         # Number of minimum Relays
  node_group_relays_max                = 20                        # Number of maximum Relays
  node_group_relays_droplet_size       = "c-2"                     # Relays Instance Type
  node_group_relays_volume_size        = 50                        # Volume size in GB for Relays
}

output "module_output" {
  sensitive = true
  value     = module.red5pro
}
```

---

## Red5 Pro Stream Manager cluster with Load Balancer Stream Managers (autoscale) - [Example](https://github.com/red5pro/terraform-digitalocean-red5pro/tree/master/examples/autoscale)

- VPC
- Public subnet
- Firewall for Stream Manager 2.0
- Firewall for Kafka
- Firewall for Red5 Pro (SM2.0) Autoscaling nodes
- SSH key pair (use existing or create a new one)
- Standalone Kafka instance
- Stream Manager 2.0 instance image
- Instance poll for Stream Manager 2.0 instances
- Load Balancer for Stream Manager 2.0 instances.
- SSL certificate for Application Load Balancer. Options:
  - Create Load Balancer with SSL
  - Create Load Balancer without SSL
- Red5 Pro (SM2.0) node instance image (origins, edges, transcoders, relays)
- Red5 Pro (SM2.0) Autoscaling node group (origins, edges, transcoders, relays)

## Usage (autoscale)

```hcl

provider "digitalocean" {
  token                     = "dop_v1_example"                                               # Digital Ocean token (https://cloud.digitalocean.com/account/api/tokens)
}

module "red5pro" {
  source                     = "../../"
  digital_ocean_region       = "nyc1"                                                        # Digital Ocean region where resources will create
  ubuntu_version             = "22.04"                                                       # The version of ubuntu which is used to create droplet, it can either be 20.04 or 22.04
  type                       = "autoscale"                                                     # Deployment type: standalone, cluster, autoscale
  name                       = "red5pro-autoscale"                                             # Name to be used on all the resources as identifier
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
  stream_managers_amount       = 2                                                           # Total number stream manager required to setup in autoscale
  stream_manager_droplet_size  = "c-4"                                                       # Stream Manager droplet size
  stream_manager_auth_user     = "example_user"                                              # Stream Manager 2.0 authentication user name
  stream_manager_auth_password = "example_password"                                          # Stream Manager 2.0 authentication password

  # Terraform Service configuration
  kafka_standalone_droplet_size    = "c-4"                                                   # Terraform service droplet size

  # Load Balancer configuration for Stream Manager
  create_load_balancer_with_ssl  = true                                                      # Create a new SSL certificate for Load Balancer (autoscaling)
  load_balancer_size             = "lb-small"                                                # The size of the Load Balancer. It must be either lb-small, lb-medium, or lb-large  
  load_balancer_cert_chain       = "./chain.pem"                                             # Only If 'lb_ssl_create' = true  File path for SSL/TLS CA Certificate chain (autoscaling)
  load_balancer_cert_private_key = "./privkey.pem"                                           # Only If 'lb_ssl_create' = true  File path for SSL/TLS Certificate Private Key (autoscaling)
  load_balancer_cert_public      = "./cert.pem"                                              # Only If 'lb_ssl_create' = true  File path for SSL/TLS Certificate Public Cert (autoscaling)

  # Red5 Pro general configuration
  red5pro_license_key         = "1111-2222-3333-4444"                                        # Red5 Pro license key (https://account.red5pro.com/login)
  red5pro_api_enable          = true                                                         # true - enable Red5 Pro server API, false - disable Red5 Pro server API (https://www.red5pro.com/docs/development/api/overview/)
  red5pro_api_key             = "examplekey"                                                 # Red5 Pro server API key (https://www.red5pro.com/docs/development/api/overview/)

  # Red5 Pro autoscaling Origin node image configuration
  node_image_create           = true                                                         # Default: true for Autoscaling and Cluster, true - create new Origin node image, false - not create new Origin node image
  node_image_droplet_size     = "c-2"                                                        # droplet type for Origin node image

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
  node_group_edges_min                 = 1                         # Number of minimum Edges
  node_group_edges_max                 = 40                        # Number of maximum Edges
  node_group_edges_droplet_size        = "c-2"                     # Edges Instance Type
  node_group_edges_volume_size         = 50                        # Volume size in GB for Edges
  node_group_transcoders_min           = 0                         # Number of minimum Transcoders
  node_group_transcoders_max           = 20                        # Number of maximum Transcoders
  node_group_transcoders_droplet_size  = "c-2"                     # Transcoders Instance Type
  node_group_transcoders_volume_size   = 50                        # Volume size in GB for Transcoders
  node_group_relays_min                = 0                         # Number of minimum Relays
  node_group_relays_max                = 20                        # Number of maximum Relays
  node_group_relays_droplet_size       = "c-2"                     # Relays Instance Type
  node_group_relays_volume_size        = 50                        # Volume size in GB for Relays
}

output "module_output" {
  sensitive = true
  value     = module.red5pro
}
```

---

**NOTES**

> - WebRTC broadcast does not work in WEB browsers without an HTTPS (SSL) certificate.
> - To activate HTTPS/SSL, you need to add a DNS A record for the public IP address of your Red5 Pro server or Stream Manager 2.0.
---
