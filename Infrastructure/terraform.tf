terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
  #Modify to where you want the configuration from
  #Can also be a .tfstate file (located in S3 bucket)
  

  backend "s3"{
    bucket = "jenkins-project-infrastructure"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
    
  required_version = ">= 1.2"
}

provider "aws" {
  region = var.project_region
}
