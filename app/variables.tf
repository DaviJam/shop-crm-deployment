variable "secret_path" {
  type    = string
  default = "<paste your secret path>"
}

variable "region" {
  type    = string
  default = "<paste your required region>"
}

variable "author_name" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_avail_zone" {
  type = string
}


variable "main_dir" {
  type = string
}

