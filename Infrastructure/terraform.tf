terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  #Modify to where you want the configuration from
  #Can also be a .tfstate file (located in S3 bucket)
  cloud { 
    
    organization = "Andres-Cabral-Organization-Terraform" 

    workspaces { 
      name = "Infrastructure-workspace" 
    } 
  } 
    
  required_version = ">= 1.2"
}

provider "aws" {
  region = "us-east-1"
}
