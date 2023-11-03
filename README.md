# Digital Ocean Red5 Pro Terraform module
[Red5 Pro](https://www.red5.net/) is a real-time video streaming server plaform known for its low-latency streaming capabilities, making it ideal for interactive applications like online gaming, streaming events and video conferencing etc.

This a reusable Terraform installer module for [Red5 Pro](https://www.red5pro.com/docs/installation/installation/do-install/) that provisions infrastucture over [Digital Ocean(DO)](https://www.digitalocean.com/).

## This module has 3 variants of Red5 Pro deployments

* **single** - Single droplet with installed and configured Red5 Pro server
* **cluster** - Stream Manager cluster (MySQL DB + Stream Manager droplet + Autoscaling Node group with Origin, Edge, Transcoder, Relay droplets)
* **autoscaling** - Autoscaling Stream Managers (MySQL DB + Load Balancer + Autoscaling Stream Managers + Autoscaling Node group with Origin, Edge, Transcoder, Relay droplets)

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
* Download Red5 Pro Terraform controller for Digital Ocean: (Example: terraform-cloud-controller-0.0.0.jar) https://account.red5pro.com/downloads
* Download Red5 Pro Terraform Service : (Example: terraform-service-0.0.0.zip) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Get Digital Ocean API key or use existing (To access Digital Ocean Cloud) 
  * Follow the documentation for generating API keys - https://docs.digitalocean.com/reference/api/create-personal-access-token/
* Copy Red5 Pro server build, Terraform service and Terraform controller to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
cp ~/Downloads/terraform-cloud-controller-0.0.0.jar ./
cp ~/Downloads/terraform-service-0.0.0.zip ./
```

## Single Red5 Pro server deployment (single) - [Example](https://github.com/red5pro/terraform-do-red5pro/)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Firewall** - This Terrform module create a new Firewall in Digital Ocean.
* **Droplet Size** - Select the appropriate droplet size based on the usecase from Digital Ocean.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).

## Usage (single)

```hcl
provider "digitalocean" {
  token                     = ""                                                             # Digital Ocean token
}

module "red5pro" {
  source                    = "../../"
  digital_ocean_region      = ""                                                             # Digital Ocean region where resources will create eg: blr1

  type                      = "single"                                                       # Deployment type: single, cluster, autoscaling
  name                      = ""                                                             # Name to be used on all the resources as identifier
  digital_ocean_project     = true                                                           # Create a new project in Digital Ocean
  project_name              = "Exaple-Project"                                               # New Project name in digital Ocean

  path_to_red5pro_build     = "./red5pro-server-0.0.0.0-release.zip"                         # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_create            = true                                                           # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key_name"                                             # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "./example.pem"                                                # Path to existing SSH private key
  
  # VPC configuration
  vpc_create                = true                                                           # true - create new VPC, false - use existing VPC
  vpc_name_existing         = "example-vpc"                                                  # VPC name of existing VPC if vpc_create is false
 
  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = false                                         # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"                         # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                                 # Password for Let's Encrypt SSL certificate
  
  # Single Red5 Pro server Droplet configuration
  single_droplet_size                        = "c-4"                                         # Droplet size for Red5 Pro server

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

}
```

---

## Red5 Pro Stream Manager cluster deployment (cluster) - [Example](https://github.com/red5pro/terraform-do-red5pro/)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Firewall** - This Terrform module create a new Firewall in Digital Ocean.
* **Droplet Size** - Select the appropriate droplet size based on the usecase from Digital Ocean.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).
* **MySQL Database** - Users have flexibility to create a MySQL databse server in Digital Ocean or install it locally on the Stream Manager
* **Terraform Server** - Uesrs can choose to create a dedicated droplet for Terraform Server or install it locally on the Stream Manager
* **Stream Manager** - Droplet will be created automatically for Stream Manager
* **Origin Node Image** - To create Digital Ocean(DO) custom image for Orgin Node type for Stream Manager node group
* **Edge Node Image** - To create Digital Ocean(DO) custom image for Edge Node type for Stream Manager node group (optional)
* **Transcoder Node Image** - To create Digital Ocean(DO) custom image for Transcoder Node type for Stream Manager node group (optional)
* **Relay Node Image** - To create Digital Ocean(DO) custom image for Relay Node type for Stream Manager node group (optional)

## Usage (cluster)

```hcl
provider "digitalocean" {
  token                     = ""                                                             # Digital Ocean token
}

module "red5pro" {
  source                    = "../../"
  digital_ocean_region      = ""                                                             # Digital Ocean region where resources will create eg: blr1

  type                      = "single"                                                       # Deployment type: single, cluster, autoscaling
  name                      = ""                                                             # Name to be used on all the resources as identifier
  digital_ocean_project     = true                                                           # Create a new project in Digital Ocean
  project_name              = "Exaple-Project"                                               # New Project name in digital Ocean

  path_to_red5pro_build     = "./red5pro-server-0.0.0.0-release.zip"                         # Absolute path or relative path to Red5 Pro server ZIP file

  # SSH key configuration
  ssh_key_create            = true                                                           # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key_name"                                             # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "./example.pem"                                                # Path to existing SSH private key
  
  # VPC configuration
  vpc_create                = true                                                           # true - create new VPC, false - use existing VPC
  vpc_name_existing         = "example-vpc"                                                  # VPC name of existing VPC if vpc_create is false
 
  # Single Red5 Pro server HTTPS/SSL certificate configuration
  https_letsencrypt_enable                   = false                                         # true - create new Let's Encrypt HTTPS/SSL certificate, false - use Red5 Pro server without HTTPS/SSL certificate
  https_letsencrypt_certificate_domain_name  = "red5pro.example.com"                         # Domain name for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_email        = "email@example.com"                           # Email for Let's Encrypt SSL certificate
  https_letsencrypt_certificate_password     = "examplepass"                                 # Password for Let's Encrypt SSL certificate
  
  # Single Red5 Pro server Droplet configuration
  single_droplet_size                        = "c-4"                                         # Droplet size for Red5 Pro server

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

}
```

---

## Red5 Pro Stream Manager cluster with Load Balancer Stream Managers (autoscaling) - [Example](https://github.com/red5pro/terraform-do-red5pro/)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Firewall** - This Terrform module create a new Firewall in Digital Ocean.
* **Droplet Size** - Select the appropriate droplet size based on the usecase from Digital Ocean.
* **Load Balancer** - Digital Ocean load balancer for Stream Managers will be created automatically
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).
* **MySQL Database** - Users have flexibility to create a MySQL databse server in Digital Ocean or install it locally on the Stream Manager
* **Terraform Server** - Uesrs can choose to create a dedicated droplet for Terraform Server or install it locally on the Stream Manager
* **Stream Manager** - Droplet will be created automatically for Stream Manager
* **Origin Node Image** - To create Digital Ocean(DO) custom image for Orgin Node type for Stream Manager node group
* **Edge Node Image** - To create Digital Ocean(DO) custom image for Edge Node type for Stream Manager node group (optional)
* **Transcoder Node Image** - To create Digital Ocean(DO) custom image for Transcoder Node type for Stream Manager node group (optional)
* **Relay Node Image** - To create Digital Ocean(DO) custom image for Relay Node type for Stream Manager node group (optional)


## Usage (autoscaling)

```hcl
provider "digitalocean" {
  token                     = ""                                                           # Digital Ocean token
}

module "red5pro_autoscale" {
  source                    = "../../"
  digital_ocean_token       = ""                                                            # Digital Ocean token
  digital_ocean_region      = ""                                                            # Digital Ocean region where resources will create eg: blr1
  type                      = "autoscaling"                                                 # Deployment type: single, cluster, autoscaling
  name                      = ""                                                            # Name to be used on all the resources as identifier
  digital_ocean_project     = true                                                          # Create a new project in Digital Ocean
  project_name              = "Example-Project"                                             # New Project name in digital Ocean

  path_to_red5pro_build     = "./red5pro-server-0.0.0.0-release.zip"                        # Absolute path or relative path to Red5 Pro server ZIP file
  path_to_terraform_cloud_controller = "./terraform-cloud-controller-0.0.0.jar"             # Absolute path or relative path to terraform cloud controller jar file
  path_to_terraform_service_build = "./terraform-service-0.0.0.zip"                         # Absolute path or relative path to terraform service ZIP file

  # SSH key configuration
  ssh_key_create            = false                                                         # true - create new SSH key, false - use existing SSH key
  ssh_key_name              = "example_key"                                                 # Name for new SSH key or for existing SSH key
  ssh_private_key_path      = "./example.pem"                                               # Path to existing SSH private key
  
  # VPC configuration
  vpc_create                = false                                                         # true - create new VPC, false - use existing VPC
  vpc_name_existing         = "example-vpc"                                                 # VPC name of existing VPC if vpc_create is false

  # Stream Manager Configuration
  stream_manager_droplet_size = "c-4"                                                       # Stream Manager droplet size
  stream_manager_api_key      = ""                                                          # Stream Manager api key

  # Database Configuration
  mysql_database_size       = "db-s-1vcpu-2gb"                                              # New MysQL database size

  # Terraform Service configuration
  terra_api_token             = ""                                                          # Terraform api token
  terra_parallelism           = "20"                                                        # Terraform parallelism
  terraform_service_droplet_size = "c-4"                                                    # Terraform droplet size 

  # Load Balancer configuration for Stream Manager
  lb_ssl_create               = true                                                         # Create a new SSL certificate for Load Balancer created in DO (autoscaling)
  lb_ssl_certificate_type     = "custom"                                                     # If 'lb_ssl_create' = true, define the type of new SSL certificate. Only 'custom' or 'lets_encrypt'. In the case of 'custom' specify the path of keys in below variables[cert_fullchain, cert_private_key, leaf_public_cert], in 'lets_encrypt' specify the already created domain name for SSL create.
  existing_lb_domain_name     = "example.com"                                                # Only required when 'lb_ssl_certificate_type' = lets_encrypt
  lb_size_count               = 2                                                            # The size of the Load Balancer. It must be in the range (1, 100).
  lb_exist_ssl_cert_name      = ""                                                           # If 'lb_ssl_create' = false, Use existing SSL certificate for Load Balancer already uploaded in DO (autoscaling)
  new_lb_cert_name            = "example_certificate_name"                                   # Only If 'lb_ssl_create' = true, New Load Balancer certificate name
  cert_fullchain              = "./example/fullchain.pem"                                    # Only If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = custom, File path for SSL/TLS CA Certificate Fullchain (autoscaling)
  cert_private_key            = "./example/privkey.pem"                                      # Only If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = custom, File path for SSL/TLS Certificate Private Key (autoscaling)
  leaf_public_cert            = "./example/cert.pem"                                         # Only If 'lb_ssl_create' = true && 'lb_ssl_certificate_type' = custom, File path for SSL/TLS Certificate Public Cert (autoscaling)

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
```

---

**NOTES**

* To activate HTTPS/SSL you need to add DNS A record for Elastic IP (single/cluster) or CNAME record for Load Balancer DNS name (autoscaling)

---

