MACOS_VERSION=sequoia-xcode
MACOS_VM_NAME=sequoia-codeql

OS_TYPE := iOS
OS_VERSION := 18.3.2

artifact_dir=artifacts/Build/binary

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

.PHONY: codeql-db-jsc
codeql-db-jsc:
	@echo " > Building WebKit (JSC) CodeQL Database for $(OS_TYPE) $(OS_VERSION)"
	@OS_TYPE="$(OS_TYPE)" OS_VERSION="$(OS_VERSION)" cirrus run --verbose --output simple -e OS_TYPE -e OS_VERSION --artifacts-dir artifacts jsc
	@echo " 🎉 Done! 🎉"

.PHONY: codeql-db-wk
codeql-db-wk:
	@echo " > Building WebKit CodeQL Database for $(OS_TYPE) $(OS_VERSION)"
	@OS_TYPE="$(OS_TYPE)" OS_VERSION="$(OS_VERSION)" cirrus run --verbose --output simple -e OS_TYPE -e OS_VERSION --artifacts-dir artifacts webkit
	@echo " 🎉 Done! 🎉"	

.PHONY: codeql-db
codeql-db: codeql-db-jsc codeql-db-wk

${artifact_dir}/webkit-codeql-${OS_TYPE}-${OS_VERSION}-release.zip.sha256:
	@echo " > Creating SHA256 checksum for webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip"
	shasum -a 256 $(artifact_dir)/webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip > $(artifact_dir)/webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip.sha256

.PHONY: release-webkit
release-webkit: ${artifact_dir}/webkit-codeql-${OS_TYPE}-${OS_VERSION}-release.zip.sha256
	@echo " > Creating release for $(OS_TYPE) $(OS_VERSION)"
	gh release upload v$(OS_VERSION) --clobber $(artifact_dir)/webkit-compile_commands-$(OS_TYPE)-$(OS_VERSION)-release.zip
	gh release upload v$(OS_VERSION) --clobber $(artifact_dir)webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip
	gh release upload v$(OS_VERSION) --clobber $(artifact_dir)webkit-codeql-$(OS_TYPE)-$(OS_VERSION)-release.zip.sha256
	@echo " 🎉 Done! 🎉"

${artifact_dir}/jsc-codeql-${OS_VERSION}-release.zip.sha256:
	@echo " > Creating SHA256 checksum for jsc-codeql-$(OS_VERSION)-release.zip"
	shasum -a 256 $(artifact_dir)/jsc-codeql-$(OS_VERSION)-release.zip > $(artifact_dir)/jsc-codeql-$(OS_VERSION)-release.zip.sha256

.PHONY: release-jsc
release-jsc: ${artifact_dir}/jsc-codeql-${OS_VERSION}-release.zip.sha256
	@echo " > Creating release for JSC $(OS_VERSION)"
	gh release upload v$(OS_VERSION) --clobber $(artifact_dir)/jsc-compile_commands-$(OS_VERSION)-release.zip
	gh release upload v$(OS_VERSION) --clobber $(artifact_dir)/jsc-codeql-$(OS_VERSION)-release.zip
	gh release upload v$(OS_VERSION) --clobber $(artifact_dir)/jsc-codeql-$(OS_VERSION)-release.zip.sha256
	@echo " 🎉 Done! 🎉"

.PHONY: release
release: release-jsc release-webkit

clean:
	@echo " > Cleaning up"
	@rm -rf ./WebKit
	@rm -rf ./webkit-codeql
	@rm -rf ./jsc-codeql
	@rm -rf ./artifacts
	@echo " 🎉 Done! 🎉"

.DEFAULT_GOAL := build-vm