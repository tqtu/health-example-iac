module "network" {
  source             = "../../modules/vpc"
  env                = "qa"
  aws_region         = "ap-southeast-2"
  vpc_cidr           = "10.10.0.0/16"
  public_subnet_cidr = "10.10.1.0/24"
}

module "compute" {
  source        = "../../modules/ec2-instance"
  env           = "qa"
  vpc_id        = module.network.vpc_id
  subnet_id     = module.network.public_subnet_id
  ami_id        = "ami-0c2016462719f9b5a" # Ubuntu 24.04 Sydney
  instance_type = "t3.micro"
  key_name      = "key_learn_aws_instance_free"
}

output "qa_server_ip" {
  value = module.compute.server_public_ip
}
