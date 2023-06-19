terraform {
  source = "${get_terragrunt_dir()}/../modules/cluster///"
}

dependency "network" {
  config_path = "../network"
  skip_outputs=true
}

include "backend" {
  path = "${get_repo_root()}/terragrunt_backend.hcl"
}

include "common_inputs" {
  path = find_in_parent_folders("common_inputs.hcl")
  expose = true
}

include "provider" {
  path = find_in_parent_folders("provider.hcl")
}

inputs = merge(
  include.common_inputs.inputs,
  {
    project="bigdata-eks",
    az_num=2,
    node_group_name="main",
    subnet_mask=22,
    vpc_id="vpc-",
    igw_id="igw-",
    cidr_block="10.0.240.0/20"
  }
)