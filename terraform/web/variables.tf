variable "web_instance_type" {
  type = string
  default = "t2.micro"
  description = "Instance type to use for Web instances"
}

variable "web_instance_count" {
  type = number
  default = 1
  description = "Number of instances to create for the Web"
}

variable "web_ami" {
  type = string
  description = "Image to use for Web instances (e.g. Ubuntu, Debian)"
}

variable "web_key_name" {
  type = string
  description = "AWS Key name (SSH) to use for the Web instances"
}
