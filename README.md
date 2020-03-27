# Infrastructure of DivisionBy0-Blog

## Description
The following project contains the basic infrastructure of the [divisionby0.de](https://divisionby0.de) blog.

The blog is based on the [Gatsby starter Lumen](https://github.com/alxshelepenok/gatsby-starter-lumen) project and is delivered via AWS Cloudfront.

This project contains the basic AWS infrastructure as [Terraform](https://www.terraform.io/) scripts.

![infrastructure](./doc/2020-03-27-blog-infrastucture.png "technical infrastructure of divisionby0 blog") 

Further information regarding the infrastructure are available under [https://divisionby0.de](https://divisionby0.de/posts/blog-iac-mit-terraform).

## How to use
### Prerequisites
If you want to use this scripts you should:
* Have an AWS Acccount
* Install and configure the [AWS-CLI](https://aws.amazon.com/de/cli/)
* Install [Terraform](https://www.terraform.io/downloads.html)
* Update variables in this project to match your domain and bucket names

### Deploying infrastructure
First initialize the Terraform working directory.
```
terraform init
```

Applying infrastructure.
```
terraform apply
```

When applying the infrastructure terraform will create a hosted zone in AWS Route53. Make sure the name servers of your domain points to this hosted zone, otherwise the certificate validation won't succeed.

See [docs](https://www.terraform.io/docs/commands/index.html) for further details regarding the Terraform CLI.
