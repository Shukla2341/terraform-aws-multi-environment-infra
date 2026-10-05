resource "aws_security_group" "app" {
  name        = "app-security-group"
  description = "Security group for private application EC2"
  vpc_id      = aws_vpc.main.id

  # Allow traffic inside the VPC
  ingress {
    description = "VPC internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-security-group"
  }
}
