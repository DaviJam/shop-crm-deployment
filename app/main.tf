module "ec2" {
  source              = "../Modules/EC2"
  author_name         = var.author_name
  instance_type       = var.instance_type
  private_key_path    = var.private_key_path
  availability_zone   = var.ec2_avail_zone
  sg_name             = module.sg.out-sg-name
  public_ip           = module.eip.out_eip_ip
  main_directory      = var.main_dir
}

module "sg" {
  source   = "../Modules/SG"
  tag_name = var.author_name
}

module "eip" {
  source      = "../Modules/EIP"
  author_name = var.author_name
}

resource "aws_eip_association" "eip_association" {
  allocation_id = module.eip.out_eip_id
  instance_id   = module.ec2.out-ec2-id
}

