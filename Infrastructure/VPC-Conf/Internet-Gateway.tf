#Create the internet gateway and assign it to the VPC
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.VPC_Terraform.id

  tags = {
    Name = "Internet-Gateway-Terraform-${var.project_environment}"
  }
  
}