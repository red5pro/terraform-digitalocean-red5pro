## Red5 Pro Stream Manager cluster with Load Balancer Stream Managers (autoscale) - [Example](https://github.com/red5pro/terraform-digitalocean-red5pro/tree/main/example/autoscale)

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

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Notes

> - WebRTC broadcast does not work in WEB browsers without an HTTPS (SSL) certificate.
> - To activate HTTPS/SSL, you need to add a DNS A record for the public IP address of your Red5 Pro server or Stream Manager 2.0.


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | >=2.34.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_red5pro"></a> [red5pro](#module\_red5pro) | ../../ | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_http_url"></a> [load\_balancer\_http\_url](#output\_load\_balancer\_http\_url) | Red5 Pro Server HTTP URL |
| <a name="output_load_balancer_https_url"></a> [load\_balancer\_https\_url](#output\_load\_balancer\_https\_url) | Red5 Pro Server HTTPS URL |
| <a name="output_module_output"></a> [module\_output](#output\_module\_output) | n/a |
| <a name="output_node_image_name"></a> [node\_image\_name](#output\_node\_image\_name) | Image name of the Red5 Pro Node Origin image |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | SSH key name |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
