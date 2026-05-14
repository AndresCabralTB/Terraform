terraform { 
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

    backend "S3" {

        bucket = "jenkins-project-bootstrap"
        key    = "Terraform_Backend/terraform.tfstate"
        region = var.project_region

    }

}

provider "aws" {
  region = var.project_region
}
