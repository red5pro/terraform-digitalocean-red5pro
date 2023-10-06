## Single Red5 Pro server deployment (single) - [Example](https://github.com/red5pro/terraform-do-red5pro/)

* **VPC** - This Terrform module can either create a new or use your existing VPC. If you wish to create a new VPC, set `vpc_create` to `true`, and the script will ignore the other VPC configurations. To use your existing VPC, set `vpc_create` to `false` and include your existing vpc name.
* **Firewall** - This Terrform module create a new Firewall in Digital Ocean.
* **Droplet Size** - Select the appropriate droplet size based on the usecase from Digital Ocean.
* **SSL Certificates** - User can install Let's encrypt SSL certificates or use Red5Pro server without SSL certificate (HTTP only).

## Preparation

* Install **terraform** https://developer.hashicorp.com/terraform/downloads
* Install **DO CLI** https://docs.digitalocean.com/reference/doctl/how-to/install/
* Install **jq** Linux or Mac OS only - `apt install jq` or `brew install jq` (It is using in bash scripts to create/delete Stream Manager node group using API)
* Download Red5 Pro server build: (Example: red5pro-server-0.0.0.b0-release.zip) https://account.red5pro.com/downloads
* Get Red5 Pro License key: (Example: 1111-2222-3333-4444) https://account.red5pro.com
* Get DO API key or use existing (To access Digital Ocean Cloud) 
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
| <a name="output_red5pro_server_http_url"></a> [red5pro\_server\_http\_url](#output\_red5pro\_server\_http\_url) | Red5 Pro Server HTTP URL |
| <a name="output_red5pro_server_https_url"></a> [red5pro\_server\_https\_url](#output\_red5pro\_server\_https\_url) | Red5 Pro Server HTTPS URL |
| <a name="output_red5pro_server_ip"></a> [red5pro\_server\_ip](#output\_red5pro\_server\_ip) | Red5 Pro Server IP |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | SSH key name |
| <a name="output_ssh_private_key_path"></a> [ssh\_private\_key\_path](#output\_ssh\_private\_key\_path) | SSH private key path |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC Name |
