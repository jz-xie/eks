# Deploying default provisioner and default-lt (using launch template) for Karpenter autoscaler

data "kubectl_path_documents" "karpenter_provisioners" {
  pattern = "${path.module}/karpenter_provisioners/*.yaml" # without launch template
  vars = {
    azs                     = join(",", local.azs)
    iam-instance-profile-id = "${var.cluster_name}-${local.node_group_name}"
    eks-cluster-id          = var.cluster_name
    eks-vpc-name            = var.cluster_name
  }
}

# Creates Launch templates for Karpenter
# Launch template outputs will be used in Karpenter Provisioners yaml files. Checkout this examples/karpenter/provisioners/default_provisioner_with_launch_templates.yaml
module "karpenter_launch_templates" {
  source = "git@github.com:aws-ia/terraform-aws-eks-blueprints.git//modules/launch-templates"

  eks_cluster_id = var.cluster_name

  launch_template_config = {
    linux = {
      ami                    = data.aws_ami.eks.id
      launch_template_prefix = "karpenter"
      iam_instance_profile   = "${var.cluster_name}-${var.node_group_name}"
      vpc_security_group_ids = [data.aws_security_group.worker_node_security_group.id]
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          volume_type = "gp3"
          volume_size = 200
        }
      ]
    }

    bottlerocket = {
      ami                    = data.aws_ami.bottlerocket.id
      launch_template_os     = "bottlerocket"
      launch_template_prefix = "bottle"
      iam_instance_profile   = "${var.cluster_name}-${var.node_group_name}"
      vpc_security_group_ids = [data.aws_security_group.worker_node_security_group.id]
      block_device_mappings = [
        {
          device_name = "/dev/xvda"
          volume_type = "gp3"
          volume_size = 200
        }
      ]
    }
  }

  tags = merge(local.tags, { Name = "karpenter" })
}


resource "kubectl_manifest" "karpenter_provisioner" {
  for_each  = toset(data.kubectl_path_documents.karpenter_provisioners.documents)
  yaml_body = each.value

  depends_on = [module.eks_blueprints_kubernetes_addons]
}

# resource "kubectl_manifest" "karpenter_provisioner" {
#   #   yaml_body = file("karpenter_provisioner.yaml")

#   yaml_body = <<-YAML
#       apiVersion: karpenter.sh/v1alpha5
#       kind: Provisioner
#       metadata:
#         name: default
#       spec:
#         requirements:
#           - key: karpenter.sh/capacity-type
#             operator: In
#             values: ["spot"]
#         limits:
#           resources:
#             cpu: 1000
#         providerRef:
#           name: default
#         ttlSecondsAfterEmpty: 30
#     YAML

#   # depends_on = [
#   #   module.eks_blueprints_kubernetes_addons
#   # ]
# }

# resource "kubectl_manifest" "karpenter_node_template" {
#   yaml_body = templatefile("${path.module}/karpenter_node_template.yaml",
#     { cluster_name = var.cluster_name }
#   )

#   #   yaml_body = <<-YAML
#   #       apiVersion: karpenter.k8s.aws/v1alpha1
#   #       kind: AWSNodeTemplate
#   #       metadata:
#   #         name: default
#   #       spec:
#   #         subnetSelector:
#   #           karpenter.sh/discovery: "true"
#   #         securityGroupSelector:
#   #           karpenter.sh/discovery: ${var.cluster_name}
#   #         tags:
#   #           karpenter.sh/discovery: ${var.cluster_name}
#   #     YAML

#   # depends_on = [
#   #   module.eks_blueprints_kubernetes_addons
#   # ]
# }
