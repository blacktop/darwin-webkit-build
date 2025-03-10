MACOS_VERSION=sequoia-xcode
MACOS_VM_NAME=sequoia-codeql

OS_TYPE := "iOS"
OS_VERSION := "18.3.1"

.PHONY: deps
deps:
	@echo " > Installing dependencies"
	brew install hashicorp/tap/packer
	brew install cirruslabs/cli/tart
	brew install cirruslabs/cli/cirrus

.PHONY: build-vm
build-vm:
	@echo " > Building macOS VM"
	@packer init -upgrade ./templates/codeql.pkr.hcl
	@packer build -var "macos_version=$(MACOS_VERSION)" -var "macos_vm_name=$(MACOS_VM_NAME)" ./templates/codeql.pkr.hcl
	@echo " 🎉 Done! 🎉"

.PHONY: export-vm
export-vm:
	@echo " > EXPORTING macOS VM: $(MACOS_VM_NAME)"
	@tart export $(MACOS_VM_NAME)
	@echo " 🎉 Done! 🎉"

.PHONY: codeql-db
codeql-db:
	@echo " > Building CodeQL Database for $(OS_TYPE) $(OS_VERSION)"
	@OS_TYPE="$(OS_TYPE)" OS_VERSION="$(OS_VERSION)" cirrus run -e OS_TYPE -e OS_VERSION
	@echo " 🎉 Done! 🎉"
	@cirrus run --artifacts-dir artifacts

.PHONY: release
release:
	@echo " > Creating release for $(OS_TYPE) $(OS_VERSION)"
	gh release upload v$(OS_VERSION) --clobber webkit-compile_commands-$(OS_TYPE)-$(OS_VERSION)-release.zip
	gh release upload v$(OS_VERSION) --clobber webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip
	gh release upload v$(OS_VERSION) --clobber webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip.sha256
	@echo " 🎉 Done! 🎉"

clean:
	@echo " > Cleaning up"
	@rm -rf ./WebKit
	@rm -rf ./webkit-codeql
	@rm -rf ./artifacts
	@echo " 🎉 Done! 🎉"

.DEFAULT_GOAL := build-vm