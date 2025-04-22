## Standalone Red5 Pro server deployment (standalone) - [Example](https://github.com/red5pro/terraform-digitalocean-red5pro/tree/main/example/standalone)

- VPC
- Public subnet
- Firewall for Standalone Red5 Pro server
- SSH key pair (use existing or create a new one)
- Standalone Red5 Pro server instance
- SSL certificate for Standalone Red5 Pro server instance. Options:
  - `none` - Red5 Pro server without HTTPS and SSL certificate. Only HTTP on port `5080`
  - `letsencrypt` - Red5 Pro server with HTTPS and SSL certificate obtained by Let's Encrypt. HTTP on port `5080`, HTTPS on port `443`
  - `imported` - Red5 Pro server with HTTPS and imported SSL certificate. HTTP on port `5080`, HTTPS on port `443`

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
| <a name="output_manual_dns_record"></a> [manual\_dns\_record](#output\_manual\_dns\_record) | Manual DNS record |
| <a name="output_module_output"></a> [module\_output](#output\_module\_output) | n/a |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | SSH key name |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_standalone_red5pro_server_http_url"></a> [standalone\_red5pro\_server\_http\_url](#output\_standalone\_red5pro\_server\_http\_url) | Red5 Pro Server HTTP URL |
| <a name="output_standalone_red5pro_server_https_url"></a> [standalone\_red5pro\_server\_https\_url](#output\_standalone\_red5pro\_server\_https\_url) | Red5 Pro Server HTTPS URL |
| <a name="output_standalone_red5pro_server_ip"></a> [standalone\_red5pro\_server\_ip](#output\_standalone\_red5pro\_server\_ip) | Red5 Pro Server IP |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |