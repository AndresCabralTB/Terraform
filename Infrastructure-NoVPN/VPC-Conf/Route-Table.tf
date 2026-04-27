#Beggin by declaring the Route Table for the VPC - They are in the same module, so it can be referenced directly.
resource "aws_route_table" "RouteTableVPC" {
    vpc_id = aws_vpc.VPC_Terraform.id

    tags = {
        Name = "Public-Route-Table"
    }
}

#Link a route to the Route Table. It will allow for access to the internet through an internet gateway
resource "aws_route" "RouteToIGW" {
    route_table_id = aws_route_table.RouteTableVPC.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
}

#Associate the Route Table to the subnet that you wish to have internet access to. The subnet needs to be public!
resource "aws_route_table_association" "SubnetA_Association" {
    subnet_id = aws_subnet.VPC_Subnet_A.id
    route_table_id = aws_route_table.RouteTableVPC.id
}
