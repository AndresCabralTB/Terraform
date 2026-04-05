module "AdminAccessGroup_Module" {
    source = "./Admin-Access-Conf"
}

module "IAMInstanceProfile_Module" {
    source = "./IAM-Instance-Profile"
}