resource "local_sensitive_file" "talosconfig" {
  content         = data.talos_client_configuration.this.talos_config
  filename        = "${path.module}/out/talosconfig"
  file_permission = "0600"
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename        = "${path.module}/out/kubeconfig"
  file_permission = "0600"
}

output "node_ips" {
  value = { for k, v in var.nodes : k => v.ip }
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}

output "next_steps" {
  value = <<-EOT

    PowerShell:
      $env:TALOSCONFIG = "$PWD\out\talosconfig"
      $env:KUBECONFIG  = "$PWD\out\kubeconfig"

    bash:
      export TALOSCONFIG=$PWD/out/talosconfig
      export KUBECONFIG=$PWD/out/kubeconfig

    talosctl health
    kubectl get nodes -o wide
  EOT
}
