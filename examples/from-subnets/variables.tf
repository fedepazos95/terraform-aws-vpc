variable "region" {
  type = string
}

variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}
