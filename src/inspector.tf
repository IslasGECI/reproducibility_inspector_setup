resource "aws_vpc" "inspector" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "inspector-vpc"
  }
}

resource "aws_internet_gateway" "inspector" {
  vpc_id = aws_vpc.inspector.id
  tags = {
    Name = "inspector-igw"
  }
}

resource "aws_subnet" "inspector" {
  vpc_id            = aws_vpc.inspector.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "inspector-subnet"
  }
}

resource "aws_security_group" "inspector" {
  name        = "inspector-sg"
  description = "Security group for inspector"
  vpc_id      = aws_vpc.inspector.id

  ingress {
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

resource "aws_network_interface" "inspector" {
  subnet_id       = aws_subnet.inspector.id
  security_groups = [aws_security_group.inspector.id]

  tags = {
    Name = "inspector-nic"
  }
}

resource "aws_eip" "inspector" {
  domain            = "vpc"
  network_interface = aws_network_interface.inspector.id
  depends_on        = [aws_vpc.inspector]

  tags = {
    Name = "inspector-public-ip"
  }
}

resource "aws_route_table" "inspector" {
  vpc_id = aws_vpc.inspector.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inspector.id
  }
  tags = {
    Name = "inspector-rt"
  }
}

resource "aws_route_table_association" "inspector" {
  subnet_id      = aws_subnet.inspector.id
  route_table_id = aws_route_table.inspector.id
}

resource "aws_key_pair" "inspector" {
  public_key = file("~/.ssh/id_rsa.pub")
  tags = {
    Name = "inspector-key"
  }
}

resource "aws_instance" "inspector" {
  ami           = "ami-02ebdb11bae1b2486"
  instance_type = "t3.large"
  key_name      = aws_key_pair.inspector.id

  network_interface {
    network_interface_id = aws_network_interface.inspector.id
    device_index         = 0
  }

  tags = {
    Name = "inspector"
  }

  root_block_device {
    volume_size = 128
    volume_type = "gp3"
  }
}

output "inspector_ip" {
  value = aws_eip.inspector.public_ip
}
