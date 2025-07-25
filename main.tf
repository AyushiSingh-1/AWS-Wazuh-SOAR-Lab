# main.tf

provider "aws" {
  region = "us-east-1"
}

# Create an SSH key pair to access the instances
# It assumes you have a key at ~/.ssh/id_rsa.pub. If not, run: ssh-keygen
resource "aws_key_pair" "my_key" {
  key_name   = "project-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Security Group for the SIEM Server (Wazuh)
resource "aws_security_group" "siem_sg" {
  name = "siem-sg"
  ingress {
    from_port   = 22 # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For a real project, restrict this to your IP!
  }
  ingress {
    from_port   = 443 # Wazuh Dashboard HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 1514 # Wazuh agent registration
    to_port     = 1514
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 1515 # Wazuh agent communication
    to_port     = 1515
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

# Security Group for the Victim Web Server
resource "aws_security_group" "victim_sg" {
  name = "victim-sg"
  ingress {
    from_port   = 22 # SSH
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

# Define the EC2 instances
resource "aws_instance" "siem_server" {
  ami           = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS for us-east-1
  instance_type = "t3.micro" # Free Tier! It will be slow, but it's free.
  key_name      = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.siem_sg.name]
  root_block_device{
	volume_size=30
}
  tags = { Name = "SIEM-Server" }
}

resource "aws_instance" "victim_web_server" {
  ami           = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS for us-east-1
  instance_type = "t3.micro" # Free Tier!
  key_name      = aws_key_pair.my_key.key_name
  security_groups = [aws_security_group.victim_sg.name]
  tags = { Name = "Victim-WebApp" }
}
