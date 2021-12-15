/* Private Subnets */
resource "aws_subnet" "private_subnets" {
  count                = length(var.private_subnet_cidr_blocks)
  vpc_id               = var.vpc_id
  cidr_block           = var.private_subnet_cidr_blocks[count.index]
  availability_zone_id = var.private_subnet_az[count.index]

}


/* Public Subnets */
resource "aws_subnet" "public_subnets" {
  count                = length(var.public_subnet_cidr_blocks)
  vpc_id               = var.vpc_id
  cidr_block           = var.public_subnet_cidr_blocks[count.index]
  availability_zone_id = var.public_subnet_az[count.index]

}


/* Routing table for private subnets */
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  tags = {
    Name = "private-route-table"
  }
}

/* Routing table for public subnets */
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  tags = {
    Name = "public-route-table"
  }
}

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = var.vpc_id
  tags = {
    Name = "public-subnet-igw"
  }
}

/* associate private route table to private subnets */
resource "aws_route_table_association" "private_routes" {
  count = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

/* associate public route table to public subnets */
resource "aws_route_table_association" "public_routes" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}



/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}


/* NAT Gateway*/
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name = "nat"
  }
}


resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

/* Application Load Balancer */
resource "aws_lb" "lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

  enable_deletion_protection = true

}

/* security group for load balancer */
resource "aws_security_group" "lb_sg" {
  name        = "alb_security_group"
  description = "Load balancer security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

/* alb target group */
resource "aws_lb_target_group" "group" {
  name     = "terraform-example-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

}

/* alb listener */
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.group.arn
    type             = "forward"
  }
}




/* auto scaling group */
resource "aws_autoscaling_group" "app_asg" {
  name                      = "app_autoscaling_group"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  launch_configuration      = aws_launch_configuration.web_conf.name
  vpc_zone_identifier       = [for subnet in aws_subnet.public_subnets : subnet.id]
  target_group_arns = [aws_lb_target_group.group.arn]

}



resource "aws_launch_configuration" "web_conf" {
  name          = "web_conf"
  image_id      = var.web_ami_id
  instance_type = var.web_instance_type
  security_groups = [aws_security_group.launch_config_sec_group.id]
}



/* Security Groups */
resource "aws_security_group" "launch_config_sec_group" {
  name        = "launch_config_security_group"
  description = "launch config security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }


}
