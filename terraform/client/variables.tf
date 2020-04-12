variable "client_instance_type" {
  type = string
  default = "t2.micro"
  description = "Instance type to use for clients instances"
}

variable "client_instance_count" {
  type = number
  default = 1
  description = "Number of instances to create for the clients"
}

variable "client_ami" {
  type = string
  description = "Image to use for clients instances (e.g. Ubuntu, Debian)"
}

variable "client_key_name" {
  type = string
  description = "AWS Key name (SSH) to use for the clients instances"
}
