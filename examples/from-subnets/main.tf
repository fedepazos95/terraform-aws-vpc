#
# This example demonstrates how to use VPC module to create a VPC
# and its associated subnets based on the given Subnets CIDR blocks
#

provider "aws" {
  region = var.region
}


module "vpc" {
  source = "../../"

  name            = var.name
  cidr            = var.cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
