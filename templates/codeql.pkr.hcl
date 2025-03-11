packer {
  required_plugins {
    tart = {
      version = ">= 1.14.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type = string
}

variable "macos_vm_name" {
  type = string
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-${var.macos_version}:latest"
  vm_name      = "${var.macos_vm_name}"
  cpu_count    = 6
  memory_gb    = 48
  disk_size_gb = 120
  headless     = true
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "180s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew --version",
      "brew update",
      "brew upgrade",
      "brew install jq gum cmake ninja",
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew --version",
      "brew update",
      "brew upgrade",
      "brew install codeql",
      "codeql pack download codeql/cpp-queries",
    ]
  }

}
