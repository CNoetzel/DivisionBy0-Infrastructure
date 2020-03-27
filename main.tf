// ###################################################################################
// Default provider, all resources should be created in region 'eu-central-1'
// ###################################################################################
provider "aws" {
  profile    = "default"
  region     = "eu-central-1"
}

// Include modules from different subfolders
module "blog" {
  source = "./modules/blog"
}