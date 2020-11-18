# Configure the AWS Provider
provider "aws" {
  version    = "~> 3.15.0"
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


# Create VPC
resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_prefix

  tags = {
    Name = "Exercise App"
  }
}


# Internet GateWay
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.app-vpc.id
}


# Create Route Table
resource "aws_route_table" "app-route-table" {
  vpc_id = aws_vpc.app-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Exercise App"
  }
}


# Create Subnet
resource "aws_subnet" "app-subnet-1" {
  depends_on        = [aws_internet_gateway.gw]
  vpc_id            = aws_vpc.app-vpc.id
  cidr_block        = var.subnet_prefix
  availability_zone = var.availability_zone

  tags = {
    Name = "Exercise subnet 1"
  }
}

# Associate Subnet with Route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.app-subnet-1.id
  route_table_id = aws_route_table.app-route-table.id
}


# Create Security group to allow ports 22,80
resource "aws_security_group" "security-group" {
  name        = "allow_web_traffic"
  description = "allow web inbound traffic"
  vpc_id      = aws_vpc.app-vpc.id

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH traffic"
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
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Basic Web Traffic"
  }
}


# Create Network Interface (and set Local IP)
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.app-subnet-1.id
  security_groups = [aws_security_group.security-group.id]
}


# Elastic IP
resource "aws_eip" "elastic-ip" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = tolist(aws_network_interface.web-server-nic.private_ips)[0]
  depends_on                = [aws_internet_gateway.gw, aws_network_interface.web-server-nic]
}


# find AMI of Ubuntu 20.04 image in each region
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# Create key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "exercise-app-key"
  public_key = file(var.key_public_path)
}


# Create EC2 Instance
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  tags = {
    Name = "App Server"
  }
}

# Save Server IP in Ansible inventory file
resource "local_file" "inventory" {
  content  = "${aws_instance.instance.public_ip} ansible_user=ubuntu"
  filename = "../ansible/inventory"
}


# Triger Ansible Playbook after checking the new EC2 instance is running and ssh working.
resource "null_resource" "configuration" {
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.instance.public_ip
      user        = "ubuntu"
      private_key = file(var.key_private_path)
    }

    inline = ["echo 'connected!'"]
  }

  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${aws_instance.instance.public_ip}, --private-key ${var.key_private_path} -u ubuntu -e='method=${var.installation_method}' ../ansible/main.yml"
  }
}



# Output server address
output "server_public_address" {
  value       = "http://${aws_instance.instance.public_ip}"
  description = "Open this URL in browser"
}



