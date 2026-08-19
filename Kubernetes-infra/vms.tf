# ---------------------------------------------------------------------------
# Obraz Talosa (nocloud)
# Tworzony tylko gdy var.talos_image_file_id jest puste.
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_download_file" "talos" {
  count = var.talos_image_file_id == "" ? 1 : 0

  content_type            = "import"
  datastore_id            = var.iso_datastore
  node_name               = var.proxmox_node
  file_name               = "talos-${var.talos_version}-nocloud-amd64.raw"
  url                     = "https://factory.talos.dev/image/${var.talos_schematic_id}/${var.talos_version}/nocloud-amd64.raw.xz"
  decompression_algorithm = "zst"
  overwrite               = false
  
}

locals {
  talos_image = var.talos_image_file_id != "" ? var.talos_image_file_id : proxmox_virtual_environment_download_file.talos[0].id
}

# ---------------------------------------------------------------------------
# Trzy control-plane'y, schedulowalne (to lab)
# ---------------------------------------------------------------------------

resource "proxmox_virtual_environment_vm" "talos" {
  for_each = var.nodes

  name      = each.key
  vm_id     = each.value.vmid
  node_name = var.proxmox_node
  tags      = ["talos", var.cluster_name]

  # Wanilia Talosa nie ma qemu-guest-agent, TF nie moze na niego czekac
  agent {
    enabled = false
  }

  stop_on_destroy = true
  bios            = "seabios"
  machine         = "q35"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = each.value.cores
    # "host" bywa zawodne pod zagniezdzonym Hyper-V.
    # x86-64-v2-AES spelnia minimum Talosa i jest bezpieczne.
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
    floating  = 0 # balloon off, etcd tego nie lubi
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    import_from  = local.talos_image
    size         = each.value.disk
    ssd          = true
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # nocloud: stad Talos bierze adresacje przy pierwszym boocie
  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.subnet_cidr}"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
