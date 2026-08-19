terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true # self-signed cert w labie

  # Bez ssh-agenta - na Windowsie potrafi odmawiac wspolpracy.
  # Klucz musi byc bez passphrase i wgrany do authorized_keys roota.
  ssh {
    agent       = false
    username    = "root"
    private_key = file(pathexpand(var.ssh_private_key_path))
  }
}
