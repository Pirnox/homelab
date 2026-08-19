locals {
  bootstrap_ip     = var.nodes[var.bootstrap_node].ip
  cluster_endpoint = "https://${local.bootstrap_ip}:6443"
  node_ips         = [for n in var.nodes : n.ip]
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "this" {
  for_each = var.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.ip
  endpoint                    = each.value.ip

  config_patches = concat(
    [
      yamlencode({
        machine = {
          install = {
            disk = var.install_disk
          }
          network = {
            interfaces = [
              {
                deviceSelector = { driver = "virtio_net" }
                addresses      = ["${each.value.ip}/${var.subnet_cidr}"]
                routes = [
                  {
                    network = "0.0.0.0/0"
                    gateway = var.gateway
                  }
                ]
              }
            ]
            nameservers = [var.nameserver]
          }
        }
        cluster = {
          allowSchedulingOnControlPlanes = true
        }
      })
    ],
    var.cni_none ? [
      yamlencode({
        cluster = {
          network = { cni = { name = "none" } }
          proxy   = { disabled = true }
        }
      })
    ] : []
  )

  depends_on = [proxmox_virtual_environment_vm.talos]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
  endpoint             = local.bootstrap_ip

  depends_on = [talos_machine_configuration_apply.this]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = local.node_ips
  endpoints            = local.node_ips
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
  endpoint             = local.bootstrap_ip

  depends_on = [talos_machine_bootstrap.this]
}

data "talos_cluster_health" "this" {
  client_configuration   = talos_machine_secrets.this.client_configuration
  control_plane_nodes    = local.node_ips
  endpoints              = local.node_ips
  skip_kubernetes_checks = var.cni_none # bez CNI node'y nie beda Ready

  depends_on = [talos_cluster_kubeconfig.this]

  timeouts = {
    read = "15m"
  }
}
