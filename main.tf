Q) Create a vpc, subnets, igw, rt and inside an ec2 install apache httpd and access it with port 80
provider "aws"{
        region = "ap-south-1"
        access_key = ""
        secret_key = ""

}

###########Creating vpc#############

resource "aws_vpc" "test"{
        cidr_block = "10.10.0.0/16"
        tags = {
                name = "vpc-a"
        }
}

###########Creating subnet##########

resource "aws_subnet" "subnet1"{
        vpc_id = "${aws_vpc.test.id}"
        cidr_block = "10.10.1.0/24"
        availability_zone = "ap-south-1a"
tags = {
    Name = "Public_subnet"
  }
}

resource "aws_subnet" "subnet2"{
        vpc_id = "${aws_vpc.test.id}"
        cidr_block = "10.10.2.0/24"
        availability_zone = "ap-south-1b"
tags = {
    Name = "Private_subnet"
  }
}

###########Creating Igw##############

resource "aws_internet_gateway" "test_igw"{
        vpc_id = "${aws_vpc.test.id}"


tags = {
    Name = "igw"
  }
}

#########creating route table###########

resource "aws_route_table" "publicrt"{
        vpc_id = "${aws_vpc.test.id}"
        route{
                cidr_block = "0.0.0.0/0"
                gateway_id = "${aws_internet_gateway.test_igw.id}"
         
 }
        tags = {
           Name = "public rt"
}
}

#########route table association#########

resource "aws_route_table_association" "public-1"{
        route_table_id = "${aws_route_table.publicrt.id}"
        subnet_id = "${aws_subnet.subnet1.id}"
}

resource "aws_route_table_association" "public-2"{
        route_table_id = "${aws_route_table.publicrt.id}"
        subnet_id = "${aws_subnet.subnet2.id}"
}

#########Security Group###########

resource "aws_security_group" "sg" {
  
  vpc_id = "${aws_vpc.test.id}"

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

###########aws instance############

resource "aws_instance" "web" {
        ami = "ami-0d1e92463a5acf79d" 
        instance_type = "t2.micro"
        subnet_id = "${aws_subnet.subnet1.id}"
        key_name = "linux-kp"
        security_groups = [aws_security_group.sg.id]

  user_data = <<-EOF
  #!/bin/bash
   sudo yum install httpd -y
   sudo systemctl httpd start
   echo "<h1>Learning Terraform</h1>" /var/www/html/index.html
  EOF

  tags = {
    Name = "web_instance"
  } 
  } 

######Elastic-ip########

resource "aws_eip" "my_eip"{
        instance = aws_instance.web.id
}
