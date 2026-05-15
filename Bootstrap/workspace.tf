terraform { 
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

    backend "s3" {
        bucket = "jenkins-project-bootstrap"
        key    = "Terraform_Backend/terraform.tfstate"
        region = "us-east-1"
    }

}

provider "aws" {
  region = var.project_region
}
