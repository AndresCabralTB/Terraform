terraform { 
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  cloud { 
    
    organization = "Andres-Cabral-Organization-Terraform" 

    workspaces { 
      name = "Bootstrap-workspace" 
    } 
  } 
}

provider "aws" {
  region = "us-east-1"
}
