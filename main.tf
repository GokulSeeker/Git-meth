#########AWS_Provider

provider "aws" {
    region = "${var.region}"
  
}

terraform {
   backend "s3" {
    bucket = "terraform-whizs3-statestore"
    key    = "workspaces/terraform.tfstate"
    region = "us-east-1" 
}
  
  }

########Creation on VPC

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      Name = "Whizvpc"
    }
  
}

##########################Creation of publice and private subnet

resource "aws_subnet" "public_subnet1" {
    cidr_block = "10.0.0.0/24"
    vpc_id = "${aws_vpc.vpc.id}"
    map_public_ip_on_launch = true

    tags = {
      Name = "Public_subnet"
    }
      
}

resource "aws_subnet" "private_subnet1" {
    cidr_block = "10.0.1.0/24"
    vpc_id = "${aws_vpc.vpc.id}"
    

    tags = {
      Name = "Private_subnet"
    }
      
}

################Internet_gateway

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags = {
      Name = "internet gateway"
    }

}

#########Route_table

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
}

resource "aws_route_table_association" "subnetassociation" {
  subnet_id = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.route.id
}

###### NATgateway_route



resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.elastic.id
  subnet_id = aws_subnet.public_subnet1.id

  tags = {
    Name = "natgw"
  }
}

resource "aws_eip" "elastic" {
   domain = "vpc"
}
resource "aws_route" "nat_route" {
   route_table_id = aws_vpc.vpc.main_route_table_id
   destination_cidr_block = "0.0.0.0/0"
   nat_gateway_id = aws_nat_gateway.nat.id
}

###########Security_group

resource "aws_security_group" "whiz_SG" {
  
  name = "whiz_security"
  description = "whiz_security"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
      }

   ingress {
    from_port = 80
    to_port = 80
    protocol = "http"
    cidr_blocks = ["0.0.0.0/0"]
      }
   
   ingress {
    from_port = 10050
    to_port = 10050
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
      }

    ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
      }


   egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
      }
}

########EC2_instance_creation

resource "aws_instance" "public_whiz" {
    ami = "${var.ami}"
    instance_type = "${var.instance_type}"
    vpc_security_group_ids = ["${aws_security_group.whiz_SG.id}"]
    subnet_id = aws_subnet.public_subnet1.id
    associate_public_ip_address = true
    key_name = "whizkey"
    tags = {
      Name = "Publicinstanceee"
    }

    depends_on = [ aws_security_group.whiz_SG ]
}


resource "aws_instance" "privateinstance" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.whiz_SG.id}"]
  subnet_id = aws_subnet.private_subnet1.id
  associate_public_ip_address = false
  tags = {
    Name = "Private_instance"
  }

  depends_on = [ aws_security_group.whiz_SG ]
}