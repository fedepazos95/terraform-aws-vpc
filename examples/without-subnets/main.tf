#
# This example demonstrates how to use VPC module to create a VPC
# without associated subnets
#

provider "aws" {
  region = var.region
}


module "vpc" {
  source = "../../"

  name = var.name
  cidr = var.cidr
}
