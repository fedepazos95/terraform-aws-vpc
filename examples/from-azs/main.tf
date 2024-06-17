#
# This example demonstrates how to use VPC module to create a VPC
# and its associated subnets based on the given Availability Zones
#

provider "aws" {
  region = var.region
}


module "vpc" {
  source = "../../"

  name = var.name
  cidr = var.cidr
  azs  = var.availability_zones
}
