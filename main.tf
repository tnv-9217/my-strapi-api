# Configure AWS provider
provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

# Variables
variable "instance_type" {
  default = "t2.micro"  # Instance type for your Strapi app server
}

variable "ami_id" {
  default = "ami-0e001c9271cf7f3b9"  # Update with your desired AMI ID (e.g., Ubuntu)
}

# Security Group for Strapi app
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Security group for Strapi application"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Add more ingress rules as needed (e.g., for SSH access, HTTPS, etc.)
}

# EC2 Instance for Strapi app
resource "aws_instance" "strapi_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = "strapi"  # Replace with your SSH key pair name

  # Replace with your preferred subnet ID and security group ID
  subnet_id              = "subnet-0bc71c334d24376ae"
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  tags = {
    Name = "StrapiAppInstance"
  }

   # Provisioning script to install Strapi
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y curl",
      "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo npm install -g strapi@latest",
      "mkdir strapi-app",
      "cd strapi-app",
      "strapi new my-strapi-app --quickstart",
      "cd my-strapi-app",
      "npm run develop"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"  # Replace with appropriate user for your AMI
      private_key = file("./strapi.pem")  # Adjust path to your SSH private key
      host        = aws_instance.strapi_instance.public_ip
      timeout     = "10m"  # Adjust timeout as needed
    }
  }
}

# Output the public IP of the instance
output "strapi_instance_public_ip" {
  value = aws_instance.strapi_instance.public_ip
}
