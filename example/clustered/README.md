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
* Copy Red5 Pro server build, Terraform service and Terraform controller to the root folder of your project

Example:  

```bash
cp ~/Downloads/red5pro-server-0.0.0.b0-release.zip ./
cp ~/Downloads/terraform-cloud-controller-0.0.0.jar ./
cp ~/Downloads/terraform-service-0.0.0.zip ./
```

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Notes

* To activate HTTPS/SSL you need to add DNS A record for Elastic IP of Red5 Pro server
* Note that this example may create resources which can cost money. Run `terraform destroy` when you don't need these resources.


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | >=2.28.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_digitalocean"></a> [digitalocean](#provider\_digitalocean) | >=2.28.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_red5pro"></a> [red5pro](#module\_red5pro) | ../../ | N/A |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_host"></a> [database\_host](#output\_database\_host) | MySQL database host |
| <a name="output_database_password"></a> [database\_password](#output\_database\_password) | Database Password |
| <a name="output_database_port"></a> [database\_port](#output\_database\_port) | Database Port |
| <a name="output_database_user"></a> [database\_user](#output\_database\_user) | Database User |
| <a name="output_node_edge_image"></a> [node\_edge\_image](#output\_node\_edge\_image) | Image name of the Red5 Pro Node Edge image |
| <a name="output_node_origin_image"></a> [node\_origin\_image](#output\_node\_origin\_image) | Image name of the Red5 Pro Node Origin image |
| <a name="output_node_relay_image"></a> [node\_relay\_image](#output\_node\_relay\_image) | Image name of the Red5 Pro Node Relay image |
| <a name="output_node_transcoder_image"></a> [node\_transcoder\_image](#output\_node\_transcoder\_image) | Image name of the Red5 Pro Node Transcoder image |
| <a name="output_red5pro_server_http_url"></a> [red5pro\_server\_http\_url](#output\_red5pro\_server\_http\_url) | Red5 Pro Server HTTP URL |
| <a name="output_red5pro_server_https_url"></a> [red5pro\_server\_https\_url](#output\_red5pro\_server\_https\_url) | Red5 Pro Server HTTPS URL |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | SSH key name |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_stream_manager_ip"></a> [stream\_manager\_ip](#output\_stream\_manager\_ip) | Red5 Pro Server IP |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
