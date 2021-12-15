variable "vpc_id" {
  type        = string
  default     = ""
  description = "id of the vpc the subnets need to created"
}

/* private subnet variables */
variable "private_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "cidr blocks for private subnets"
}

variable "private_subnet_az" {
  type        = list(string)
  default     = ["us-east-2b", "us-east-2c"]
  description = "azs private subnets"
}

/* private subnet variables */
variable "public_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24", "10.0.4.0/25"]
  description = "cidr blocks for public subnets"
}

variable "public_subnet_az" {
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
  description = "azs public subnets"
}

variable "web_ami_id" {
  type        = string
  default     = ""
  description = "ami id to create web servers"
}

variable "web_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "web server instance type"
}
