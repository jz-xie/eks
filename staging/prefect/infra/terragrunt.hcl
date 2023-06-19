terraform {
  source = "${get_path_to_repo_root()}/modules/prefect/infra/"
}

include "backend" {
  path = "${get_repo_root()}/terragrunt_backend.hcl"
}

include "provider" {
  path = find_in_parent_folders("provider.hcl")
}

include "common_inputs" {
  path = find_in_parent_folders("common_inputs.hcl")
  expose = true
}

inputs = merge(
  include.common_inputs.inputs,
  {
    project="prefect"
  }
)