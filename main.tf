#creating the vpc id
resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr_block
    tags = {
      Name = "harivpc"
    }
  
}

#creating the subnets public & private subnets
#public subnet
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    # Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false
    map_public_ip_on_launch = true
    tags = {
      Name = "my_public"
    }
  
}

#private subnet

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
    tags = {
      Name = "my_private"
    }
  
}

# creating the internet gate way
# we want to access the ec2 instances we must need the internet connection
# it is a component of vpc
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
    tags = {
      Name = "myinternet_gateway"
    }
  
}

#creating route table for providing the defined path to the internet to get access to the instances which present in the subnets

resource "aws_route_table" "myrt" {
    vpc_id = aws_vpc.myvpc.id
    # below route is for allowing the internet traffic as per below mentioned ip address it will allow all users 

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "myroutetable"
    }
  
}

#route table association
# which is used to assign the route to the subnets
#below is for associating to public subnet

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.myrt.id
  
}

# below is for associating to the private subnet
resource "aws_route_table_association" "rt2" {
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.myrt.id
  
}

#creating the security groups

resource "aws_security_group" "mysg" {
    name = "my_security"
    description = "used for load balancer"
    vpc_id = aws_vpc.myvpc.id
    
    tags = {
        Name = "my_security"
    }
     ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # the reason for giving the bracket for below cidr is we have number of inbound list option
    # giving the all zeros as ip is every one can access the ip
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# creating the s3 bucket to store the instance secerts
resource "aws_s3_bucket" "mys3" {
    bucket = "harishproject348191"
    tags = {
      Name = "my_s3_bucket"
    }
  
}

# creating the ec2 instances
# below instance is creating in the public subnet
resource "aws_instance" "ec21" {
    ami = var.ami_value
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.public_subnet.id
    #the below userdata option we can at below of ec2 instance creation process
    user_data = base64encode(file("userdata.sh"))
    tags = {
      Name = "hari_instance"
    }

}
# below instance is creating in the private subnet
resource "aws_instance" "ec22" {
    ami = var.ami_value
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.private_subnet.id
    tags = {
      Name = "reddy_instance"
    }
}

