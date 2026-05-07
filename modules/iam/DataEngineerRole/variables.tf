variable "role_name" {
    description = "Name of the IAM Role"
    type = string
    default = "DataEngineerRole"
  
}

variable "Environment" {
  description = "Environment tag (dev, staging, prod)"
  type = string
  default = "dev"
}