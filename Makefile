# ============================================================================
# Skip AI - Safari Extension Makefile
# ============================================================================
# All directories and commands are abstracted to variables for easy
# configuration and portability.
#
# Three ways to override variables:
#   1. Create a .env file (will be automatically loaded if it exists)
#   2. Set in your environment: export CONFIGURATION=Debug
#   3. Pass to make: make build-ios-debug CONFIGURATION=Debug
#
# Example .env file:
#   CONFIGURATION=Debug
#   LOG_VERBOSITY=2
#   IOS_SIMULATOR_DEVICE=iPhone Air
# ============================================================================

# Include .env file if it exists
-include .env
export

# Project name
NAME := skip-ai

# Directories
BUILDDIR := build/
DERIVED_DATA := build/DerivedData
DIST_DIR := dist/
SCRIPTS_DIR := scripts/
NODE_MODULES := node_modules/
CACHE_DIR := node_modules/.cache

# Xcode project configuration
XCODE_PROJECT := Skip\ AI.xcodeproj
XCODE_SCHEME_IOS := Skip\ AI\ \(iOS\)
XCODE_SCHEME_MACOS := Skip\ AI\ \(macOS\)
XCODE_APP_NAME := Skip\ AI.app
IOS_SIMULATOR_DEVICE := iPhone 16

# Commands
PNPM := pnpm
XCODEBUILD := xcodebuild
SWIFT := swift
RUBY := ruby
OPEN := open
MKDIR := mkdir -p
RM := rm -rf
CD := cd

# Build configuration
CONFIGURATION ?= Release

# Verbosity levels: 0=quiet, 1=normal, 2=verbose, 5=debug
LOG_VERBOSITY ?= 0

# Export configuration for build commands
export CONFIGURATION
export LOG_VERBOSITY

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "=== $(NAME) Makefile ==="
	@echo ""
	@echo "Configuration variables:"
	@echo "  CONFIGURATION=$(CONFIGURATION)  (Release|Debug|Preview)"
	@echo "  LOG_VERBOSITY=$(LOG_VERBOSITY)  (0=quiet, 1=normal, 2=verbose, 5=debug)"
	@echo "  PNPM=$(PNPM)"
	@echo "  IOS_SIMULATOR_DEVICE=$(IOS_SIMULATOR_DEVICE)"
	@echo ""
	@echo "Available targets:"
	@echo "JavaScript targets:"
	@echo "  make install-js              - Install dependencies with pnpm"
	@echo "  make build-js-release        - Build production bundle"
	@echo "  make build-js-preview        - Build preview bundle"
	@echo "  make build-js-debug          - Build development bundle"
	@echo "  make watch-js-debug          - Watch and rebuild on changes (Debug)"
	@echo "  make serve-js-debug          - Serve with watch mode on port 8080 (Debug)"
	@echo "  make lint-js                 - Run ESLint with auto-fix"
	@echo "  make typecheck-js            - Run TypeScript type checking"
	@echo ""
	@echo "Xcode script targets:"
	@echo "  make add-xcode-targets       - Add Xcode targets (Swift)"
	@echo ""
	@echo "Safari iOS targets:"
	@echo "  make build-ios-release       - Build iOS app (Release)"
	@echo "  make build-ios-debug         - Build iOS app (Debug)"
	@echo "  make build-ios-preview       - Build iOS app (Preview)"
	@echo "  make run-ios-debug           - Build and run iOS app (Debug)"
	@echo "  make run-ios-release         - Build and run iOS app (Release)"
	@echo "  make run-ios-preview         - Build and run iOS app (Preview)"
	@echo "  make archive-ios             - Archive iOS app for distribution"
	@echo ""
	@echo "Safari macOS targets:"
	@echo "  make build-macos-release     - Build macOS app (Release)"
	@echo "  make build-macos-debug       - Build macOS app (Debug)"
	@echo "  make build-macos-preview     - Build macOS app (Preview)"
	@echo "  make run-macos-debug         - Build and run macOS app (Debug)"
	@echo "  make run-macos-release       - Build and run macOS app (Release)"
	@echo "  make run-macos-preview       - Build and run macOS app (Preview)"
	@echo "  make archive-macos           - Archive macOS app for distribution"
	@echo ""
	@echo "Combined targets:"
	@echo "  make build-safari-release    - Build both iOS and macOS (Release)"
	@echo "  make build-safari-debug      - Build both iOS and macOS (Debug)"
	@echo "  make build-safari-preview    - Build both iOS and macOS (Preview)"
	@echo "  make all                     - Build everything (JS + Safari Release)"
	@echo ""
	@echo "Quick aliases:"
	@echo "  make build-js                - Alias for build-js-debug"
	@echo "  make watch-js                - Alias for watch-js-debug"
	@echo "  make serve-js                - Alias for serve-js-debug"
	@echo "  make typecheck               - Alias for typecheck-js"
	@echo "  make ios                     - Alias for build-ios-debug"
	@echo "  make macos                   - Alias for build-macos-debug"
	@echo "  make safari                  - Alias for build-safari-debug"

# Install dependencies
install-js:
	@echo "Installing dependencies with $(PNPM)..."
	$(PNPM) install

# JavaScript - Internal build command
_build-js:
	@echo "Building JavaScript bundle ($(CONFIGURATION))..."
	$(PNPM) exec tsc
	$(PNPM) run build

# JavaScript - Public build targets
build-js-release: install-js
	$(MAKE) _build-js CONFIGURATION=Release

build-js-preview: install-js
	$(MAKE) _build-js CONFIGURATION=Preview

build-js-debug: install-js
	$(MAKE) _build-js CONFIGURATION=Debug

# JavaScript - Development tools
watch-js-debug: install-js
	@echo "Starting watch mode (Debug)..."
	$(PNPM) run build:watch

serve-js-debug: install-js
	@echo "Starting development server with watch mode (Debug)..."
	$(PNPM) run serve

lint-js: install-js
	@echo "Running ESLint..."
	$(PNPM) run lint

typecheck-js: install-js
	@echo "Running TypeScript type checking..."
	$(PNPM) exec tsc --noEmit

add-xcode-targets: install-js _build-js
	@echo "Adding Xcode targets (Swift)..."
	$(CD) $(SCRIPTS_DIR)/add-xcode-targets && $(SWIFT) build
	$(CD) $(SCRIPTS_DIR)/add-xcode-targets && $(SWIFT) run add-xcode-targets


# Safari iOS targets - Internal build commands
_ios-build: add-xcode-targets
	@echo "Building Safari iOS app ($(CONFIGURATION))..."
	$(XCODEBUILD) -project $(XCODE_PROJECT) \
		-scheme $(XCODE_SCHEME_IOS) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean build

_ios-run: add-xcode-targets
	@echo "Running Safari iOS app in simulator ($(CONFIGURATION))..."
	$(XCODEBUILD) -project $(XCODE_PROJECT) \
		-scheme $(XCODE_SCHEME_IOS) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		-destination 'platform=iOS Simulator,name=$(IOS_SIMULATOR_DEVICE)' \
		run

_ios-archive: add-xcode-targets
	@echo "Archiving Safari iOS app ($(CONFIGURATION))..."
	$(XCODEBUILD) -project $(XCODE_PROJECT) \
		-scheme $(XCODE_SCHEME_IOS) \
		-configuration $(CONFIGURATION) \
		-archivePath $(DERIVED_DATA)/$(NAME)-ios.xcarchive \
		archive

# Safari iOS - Public targets
build-ios-release: build-js-release
	$(MAKE) _ios-build CONFIGURATION=Release

build-ios-debug: build-js-debug
	$(MAKE) _ios-build CONFIGURATION=Debug

build-ios-preview: build-js-preview
	$(MAKE) _ios-build CONFIGURATION=Preview

run-ios-debug: build-js-debug
	$(MAKE) _ios-run CONFIGURATION=Debug

run-ios-release: build-js-release
	$(MAKE) _ios-run CONFIGURATION=Release

run-ios-preview: build-js-preview
	$(MAKE) _ios-run CONFIGURATION=Preview

archive-ios: build-js-release
	$(MAKE) _ios-archive CONFIGURATION=Release

# Safari macOS targets - Internal build commands
_macos-build: add-xcode-targets
	@echo "Building Safari macOS app ($(CONFIGURATION))..."
	$(XCODEBUILD) -project $(XCODE_PROJECT) \
		-scheme $(XCODE_SCHEME_MACOS) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean build

_macos-run: add-xcode-targets
	@echo "Running Safari macOS app ($(CONFIGURATION))..."
	$(OPEN) $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/$(XCODE_APP_NAME)

_macos-archive: add-xcode-targets
	@echo "Archiving Safari macOS app ($(CONFIGURATION))..."
	$(XCODEBUILD) -project $(XCODE_PROJECT) \
		-scheme $(XCODE_SCHEME_MACOS) \
		-configuration $(CONFIGURATION) \
		-archivePath $(DERIVED_DATA)/$(NAME)-macos.xcarchive \
		archive

# Safari macOS - Public targets
build-macos-release: build-js-release
	$(MAKE) _macos-build CONFIGURATION=Release

build-macos-debug: build-js-debug
	$(MAKE) _macos-build CONFIGURATION=Debug

build-macos-preview: build-js-preview
	$(MAKE) _macos-build CONFIGURATION=Preview

run-macos-debug: build-js-debug
	$(MAKE) _macos-build CONFIGURATION=Debug
	$(MAKE) _macos-run CONFIGURATION=Debug

run-macos-release: build-js-release
	$(MAKE) _macos-build CONFIGURATION=Release
	$(MAKE) _macos-run CONFIGURATION=Release

run-macos-preview: build-js-preview
	$(MAKE) _macos-build CONFIGURATION=Preview
	$(MAKE) _macos-run CONFIGURATION=Preview

archive-macos: build-js-release
	$(MAKE) _macos-archive CONFIGURATION=Release

# Combined Safari targets
build-safari-release: build-ios-release build-macos-release

build-safari-debug: build-ios-debug build-macos-debug

build-safari-preview: build-ios-preview build-macos-preview

# Convenience aliases for common operations
build-js: build-js-debug
watch-js: watch-js-debug
serve-js: serve-js-debug
typecheck: typecheck-js

ios: build-ios-debug
macos: build-macos-debug
safari: build-safari-debug

# Build everything
all: build-js-release build-safari-release

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	$(RM) $(BUILDDIR)
	$(RM) $(DERIVED_DATA)
	$(RM) $(DIST_DIR)
	$(RM) $(CACHE_DIR)

# Deep clean including node_modules
clean-all: clean
	@echo "Deep cleaning including node_modules..."
	$(RM) $(NODE_MODULES)
	$(RM) $(BUILDDIR)
	$(RM) $(SCRIPTS_DIR).build/


# Prepare build directory
prepare:
	@echo "Preparing build directory..."
	$(MKDIR) $(BUILDDIR)
	$(MKDIR) $(DERIVED_DATA)

.PHONY: help install-js \
	_build-js build-js-release build-js-preview build-js-debug watch-js-debug serve-js-debug lint-js typecheck-js \
	add-xcode-targets \
	_ios-build _ios-run _ios-archive build-ios-release build-ios-debug build-ios-preview run-ios-debug run-ios-release run-ios-preview archive-ios \
	_macos-build _macos-run _macos-archive build-macos-release build-macos-debug build-macos-preview run-macos-debug run-macos-release run-macos-preview archive-macos \
	build-safari-release build-safari-debug build-safari-preview \
	build-js watch-js serve-js typecheck ios macos safari all clean clean-all prepare

