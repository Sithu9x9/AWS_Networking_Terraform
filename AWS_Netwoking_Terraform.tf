terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68.0"
    }
  }
}

resource "aws_vpc" "Lab_VPC" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC"
  }
}

resource "aws_subnet" "Lab_Public_Subnet" {
  vpc_id     = aws_vpc.Lab_VPC.id
  cidr_block = "192.168.100.0/24"

  tags = {
    Name = "Public_Subnet"
  }
}

resource "aws_subnet" "Lab_Private_Subnet" {
  vpc_id     = aws_vpc.Lab_VPC.id
  cidr_block = "192.168.200.0/24"

  tags = {
    Name = "Private_Subnet"
  }
}

resource "aws_internet_gateway" "Lab_IGW" {
  vpc_id = aws_vpc.Lab_VPC.id

  tags = {
    Name = "Internet_Gateway"
  }
}

resource "aws_route_table" "Lab_Public_Route_Table" {
  vpc_id = aws_vpc.Lab_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Lab_IGW.id
  }

  tags = {
    Name = "Public Route Table"
  }
}


resource "aws_route_table_association" "Public_Subnet_Association" {
  subnet_id      = aws_subnet.Lab_Public_Subnet.id
  route_table_id = aws_route_table.Lab_Public_Route_Table.id
}

resource "aws_eip" "Elastic_IP" {
  domain   = "vpc"
  tags = {
    Name = "ElasticIP"
  }
}

resource "aws_nat_gateway" "Lab_NAT_GW" {
  allocation_id = aws_eip.Elastic_IP.id
  subnet_id     = aws_subnet.Lab_Public_Subnet.id

  tags = {
    Name = "NAT_GW"
  }
}

resource "aws_route_table" "Lab_Private_Route_Table" {
  vpc_id = aws_vpc.Lab_VPC.id

route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.Lab_NAT_GW.id
  }

tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "Private_Subnet_Association" {
  subnet_id      = aws_subnet.Lab_Private_Subnet.id
  route_table_id = aws_route_table.Lab_Private_Route_Table.id
}

resource "aws_instance" "Web_Server01" {
  ami                    = "ami-0c7217cdde317cfec"
  subnet_id              = aws_subnet.Lab_Public_Subnet.id
  key_name               = "james"
  instance_type          = "t2.micro"
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.Lab_Security.id]
  tags = {
    Name = "Web_01"
  }
}

resource "aws_instance" "DB_Instance" {
  ami                    = "ami-0c7217cdde317cfec"
  subnet_id              = aws_subnet.Lab_Private_Subnet.id
  key_name               = "james"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Lab_Security.id]
  tags = {
    Name = "Database"
  }
}

#resource "aws_eip" "Terraform_ip" {
 # instance = aws_instance.web.id
  #domain   = "vpc"
#}

resource "aws_security_group" "Lab_Security" {
  name        = "Terraform_Security"
  description = "Allow http traffic,ssh and databae"
  vpc_id      = aws_vpc.Lab_VPC.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    description = "DB"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}