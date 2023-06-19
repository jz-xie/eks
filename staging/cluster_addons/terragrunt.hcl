terraform {
  source = "${get_terragrunt_dir()}/../modules/cluster_addons///"
}

dependency "cluster" {
  config_path = "../cluster"
  skip_outputs=true
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    azs = ["az1", "az2"]
  }
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
    // azs=dependency.network.outputs.azs,
    node_group_name="main"
  }
)