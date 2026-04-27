
#Beggin by declaring the Route Table for the VPC - They are in the same module, so it can be referenced directly.
resource "aws_route_table" "PrivateRouteTableVPC" {
    vpc_id = var.vpc_id

    tags = {
        Name = "Private-Route-Table"
    }
}

#Associate the Route Table to the subnet that you wish to have internet access to. The subnet needs to be public!
resource "aws_route_table_association" "SubnetB_Association" {
    subnet_id = var.subnet_B_id
    route_table_id = aws_route_table.PrivateRouteTableVPC.id
}

resource "aws_route_table_association" "SubnetC_Association" {
    subnet_id = var.subnet_C_id
    route_table_id = aws_route_table.PrivateRouteTableVPC.id
}