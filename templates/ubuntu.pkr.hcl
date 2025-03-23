packer {
  required_plugins {
    tart = {
      version = ">= 1.14.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "ubuntu_version" {
  type    = string
  default = "24.04"
}

variable "cpu_count" {
  type    = number
  default = 4
}

variable "memory_gb" {
  type    = number
  default = 32
}

variable "disk_size_gb" {
  type    = number
  default = 50
}

source "tart-cli" "ubuntu" {
  vm_base_name = "ghcr.io/cirruslabs/ubuntu:${var.ubuntu_version}"
  vm_name      = "ubuntu-${var.ubuntu_version}-codeql"
  cpu_count    = var.cpu_count
  memory_gb    = var.memory_gb
  disk_size_gb = var.disk_size_gb
  ssh_password = "admin"
  ssh_username = "admin"
  headless     = true
  rosetta      = "rosetta"
}

build {
  sources = ["source.tart-cli.ubuntu"]

  provisioner "shell" {
    inline = [
      "echo '🚀 Updating package lists...'",
      "sudo apt-get update",
      "echo 'Installing dependencies...'",
      "sudo apt-get install -y cmake build-essential git curl unzip jq ninja-build python3-full python3-pip python3-venv",
      "cmake --version",

      #   "echo '🚀 Installing CodeQL CLI...'",
      #   "mkdir -p ~/codeql-home",
      #   "curl -L https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip -o ~/codeql-linux64.zip",
      #   "unzip ~/codeql-linux64.zip -d ~/codeql-home",

      #   "echo '🚀 Downloading CodeQL packs...'",
      #   "~/codeql-home/codeql/codeql pack download codeql/cpp-queries",

      "echo '🧹 Cleaning up...'",
      #   "rm ~/codeql-linux64.zip",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "echo 'Tart VM build complete: ubuntu-${var.ubuntu_version}-cmake'",
      "echo 'To run the VM: tart run ubuntu-${var.ubuntu_version}-cmake'"
    ]
  }
}