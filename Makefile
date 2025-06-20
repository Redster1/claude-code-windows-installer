# Claude Code Windows Installer - Build System
VERSION := 1.0.0
BUILD_DIR := build
DIST_DIR := dist
SRC_DIR := src
NSIS := makensis

.PHONY: all clean build sign test dev-setup validate-powershell lint

all: clean build

clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)

build-only: prepare
	@echo "Building Claude Code installer v$(VERSION)..."
	$(NSIS) -DVERSION=$(VERSION) \
	        -DDIST_DIR=$(PWD)/$(DIST_DIR) \
	        -DASSETS_DIR=$(PWD)/generated-images \
	        -DBUILD_DIR=$(PWD)/$(BUILD_DIR) \
	        $(SRC_DIR)/installer/main.nsi

prepare:
	@echo "Preparing build environment..."
	mkdir -p $(BUILD_DIR) $(DIST_DIR)
	cp -r $(SRC_DIR)/scripts $(BUILD_DIR)/
	cp -r $(SRC_DIR)/config $(BUILD_DIR)/
	cp -r $(SRC_DIR)/templates $(BUILD_DIR)/

sign:
	@echo "Code signing must be done on Windows with valid certificate"
	@echo "signtool sign /f certificate.pfx /p password $(DIST_DIR)/ClaudeCodeSetup.exe"

test:
	@echo "Running unit tests..."
	npm test
	@echo "Running PowerShell tests..."
	pwsh -File $(SRC_DIR)/tests/run-tests.ps1

dev-setup:
	@echo "Setting up development environment..."
	@echo "Checking for required tools..."
	@command -v makensis >/dev/null 2>&1 || { echo "NSIS not found. Install with: nix-env -iA nixpkgs.nsis"; exit 1; }
	@command -v pwsh >/dev/null 2>&1 || { echo "PowerShell not found. Install with: nix-env -iA nixpkgs.powershell"; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo "Node.js not found. Install with: nix-env -iA nixpkgs.nodejs"; exit 1; }
	@echo "Development environment ready!"

validate-powershell:
	@echo "Validating NSIS-safe PowerShell modules..."
	@for module in $(shell find $(SRC_DIR)/scripts/powershell/nsis-safe -name "*.psm1" 2>/dev/null || true); do \
		echo "Validating $$module..."; \
		pwsh -File tools/validate-powershell.ps1 -ModulePath "$$module" || exit 1; \
	done
	@echo "✅ All NSIS-safe PowerShell modules validated successfully"

lint: validate-powershell
	@echo "Linting completed successfully"

build: validate-powershell prepare
	@echo "Building Claude Code installer v$(VERSION)..."
	$(NSIS) -DVERSION=$(VERSION) \
	        -DDIST_DIR=$(PWD)/$(DIST_DIR) \
	        -DASSETS_DIR=$(PWD)/generated-images \
	        -DBUILD_DIR=$(PWD)/$(BUILD_DIR) \
	        $(SRC_DIR)/installer/main.nsi

help:
	@echo "Claude Code Windows Installer Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all                - Clean and build installer"
	@echo "  clean              - Remove build artifacts"
	@echo "  build              - Build installer executable (includes validation)"
	@echo "  prepare            - Prepare build directory"
	@echo "  validate-powershell - Validate all PowerShell modules"
	@echo "  lint               - Run all linting (alias for validate-powershell)"
	@echo "  sign               - Code sign installer (Windows only)"
	@echo "  test               - Run test suite"
	@echo "  dev-setup          - Check development environment"
	@echo "  help               - Show this help message"