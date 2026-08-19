# ---------------------------------------------------------------------------
# Proxmox
# ---------------------------------------------------------------------------

variable "proxmox_endpoint" {
  description = "URL API Proxmoxa, np. https://192.168.1.50:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Format: user@realm!token-id=uuid"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nazwa node'a w Proxmoxie (czlon hostname przed pierwsza kropka)"
  type        = string
  default     = "pve-lab"
}

variable "ssh_private_key_path" {
  description = "Klucz prywatny do roota na Proxmoxie. BEZ passphrase."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "vm_datastore" {
  description = "Datastore na dyski VM"
  type        = string
  default     = "local-lvm"
}

variable "iso_datastore" {
  description = "Datastore przyjmujacy obrazy ISO/img"
  type        = string
  default     = "local"
}

# ---------------------------------------------------------------------------
# Talos
# ---------------------------------------------------------------------------

variable "talos_version" {
  description = "Wersja Talosa. Sprawdz: https://github.com/siderolabs/talos/releases"
  type        = string
  default     = "v1.10.5"
}

variable "talos_schematic_id" {
  description = "Schematic z factory.talos.dev. Domyslny = wanilia bez rozszerzen."
  type        = string
  default     = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
}

variable "talos_image_file_id" {
  description = <<-EOT
    Zostaw pusty, zeby OpenTofu sam sciagnal obraz.
    Jesli dekompresja .xz sie wywali, sciagnij recznie na node'a i podaj tu
    file ID, np. "local:iso/talos-v1.10.5-nocloud-amd64.img"
  EOT
  type        = string
  default     = ""
}

variable "cluster_name" {
  type    = string
  default = "talos-lab"
}

variable "install_disk" {
  description = "Dysk instalacyjny widziany przez Talosa. scsi0 -> /dev/sda"
  type        = string
  default     = "/dev/sda"
}

variable "cni_none" {
  description = "true = bez Flannela i kube-proxy (pod Cilium). Na pierwszy raz zostaw false."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Siec
# ---------------------------------------------------------------------------

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "nameserver" {
  type    = string
  default = "192.168.1.1"
}

variable "subnet_cidr" {
  description = "Prefiks maski"
  type        = number
  default     = 24
}

# ---------------------------------------------------------------------------
# Node'y
# ---------------------------------------------------------------------------

variable "nodes" {
  description = "Mapa control-plane'ow. Klucz = hostname."
  type = map(object({
    vmid   = number
    ip     = string
    cores  = optional(number, 2)
    memory = optional(number, 4096)
    disk   = optional(number, 32)
  }))

  default = {
    "talos-cp-01" = { vmid = 8001, ip = "192.168.1.61" }
    "talos-cp-02" = { vmid = 8002, ip = "192.168.1.62" }
    "talos-cp-03" = { vmid = 8003, ip = "192.168.1.63" }
  }
}

variable "bootstrap_node" {
  description = "Node bootstrapujacy etcd, sluzy tez za endpoint klastra"
  type        = string
  default     = "talos-cp-01"
}
