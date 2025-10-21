#
#  Makefile
#  Skip AI
#
#  Copyright © 2025 Alexander Goodkind. All rights reserved.
#  https://goodkind.io/
#

# ============================================================================
# Skip AI - Safari Extension Makefile
# ============================================================================

-include .env
export

# Project configuration
NAME := skip-ai
XCODE_PROJECT := Skip\ AI.xcodeproj
XCODE_SCHEME_IOS := Skip\ AI\ \(iOS\)
XCODE_SCHEME_MACOS := Skip\ AI\ \(macOS\)
XCODE_APP_NAME := Skip\ AI.app
IOS_SIMULATOR_DEVICE := iPhone 16
CONFIGURATION ?= Release

# Environment variables - defaults based on CONFIGURATION
ifeq ($(CONFIGURATION),Debug)
	LOGGING_VERBOSITY ?= 5
else ifeq ($(CONFIGURATION),Preview)
	LOGGING_VERBOSITY ?= 3
else
	LOGGING_VERBOSITY ?= 2
endif
export LOGGING_VERBOSITY

# Directories
BUILDDIR := build/
DERIVED_DATA := build/DerivedData
DIST_DIR := dist/
SCRIPTS_DIR := scripts/
NODE_MODULES := node_modules/
CACHE_DIR := node_modules/.cache

# Commands
PNPM := pnpm
XCODEBUILD := xcodebuild
SWIFT := swift
OPEN := open
MKDIR := mkdir -p
RM := rm -rf
CD := cd

# Reusable command fragments
XCODE_MGR = $(CD) $(SCRIPTS_DIR)/xcode-manager && $(SWIFT) run xcode-manager
XCODEBUILD_COMMON = SKIP_JS_BUILD=1 $(XCODEBUILD) -project $(XCODE_PROJECT) -configuration $(CONFIGURATION) -derivedDataPath $(DERIVED_DATA)

# Default target
.DEFAULT_GOAL := help

# Help
help:
	@echo "=== $(NAME) Makefile ==="
	@echo ""
	@echo "Configuration:"
	@echo "  CONFIGURATION=$(CONFIGURATION)  (Release|Debug|Preview)"
	@echo "  IOS_SIMULATOR_DEVICE=$(IOS_SIMULATOR_DEVICE)"
	@echo ""
	@echo "JavaScript targets:"
	@echo "  install-js              Install dependencies with pnpm"
	@echo "  build-js-release        Build production bundle"
	@echo "  build-js-preview        Build preview bundle"
	@echo "  build-js-debug          Build development bundle"
	@echo "  watch-js-debug          Watch and rebuild on changes"
	@echo "  serve-js-debug          Serve with watch mode on port 8080"
	@echo "  lint-js                 Run ESLint with auto-fix"
	@echo "  typecheck-js            Run TypeScript type checking"
	@echo ""
	@echo "Xcode management:"
	@echo "  sync-xcode-groups       Sync file groups to Xcode targets"
	@echo "  show-version            Show current version and build"
	@echo "  bump-version-patch      Bump patch version (x.x.X)"
	@echo "  bump-version-minor      Bump minor version (x.X.0)"
	@echo "  bump-version-major      Bump major version (X.0.0)"
	@echo "  bump-build              Bump build number only"
	@echo "  fix-infoplist           Fix Info.plist files with required keys"
	@echo "  add-build-script        Add JS build phase to extension targets"
	@echo "  remove-build-script     Remove JS build phase from extension targets"
	@echo ""
	@echo "iOS targets:"
	@echo "  build-ios-release       Build iOS app (Release)"
	@echo "  build-ios-debug         Build iOS app (Debug)"
	@echo "  build-ios-preview       Build iOS app (Preview)"
	@echo "  run-ios-debug           Build and run iOS app in simulator (Debug)"
	@echo "  run-ios-release         Build and run iOS app in simulator (Release)"
	@echo "  run-ios-preview         Build and run iOS app in simulator (Preview)"
	@echo "  archive-ios             Archive iOS app for distribution"
	@echo ""
	@echo "macOS targets:"
	@echo "  build-macos-release     Build macOS app (Release)"
	@echo "  build-macos-debug       Build macOS app (Debug)"
	@echo "  build-macos-preview     Build macOS app (Preview)"
	@echo "  run-macos-debug         Build and run macOS app (Debug)"
	@echo "  run-macos-release       Build and run macOS app (Release)"
	@echo "  run-macos-preview       Build and run macOS app (Preview)"
	@echo "  archive-macos           Archive macOS app for distribution"
	@echo ""
	@echo "Combined targets:"
	@echo "  build-safari-release    Build both iOS and macOS (Release)"
	@echo "  build-safari-debug      Build both iOS and macOS (Debug)"
	@echo "  build-safari-preview    Build both iOS and macOS (Preview)"
	@echo "  all                     Build everything (JS + Safari Release)"
	@echo ""
	@echo "Quick aliases:"
	@echo "  build-js                Alias for build-js-debug"
	@echo "  watch-js                Alias for watch-js-debug"
	@echo "  serve-js                Alias for serve-js-debug"
	@echo "  typecheck               Alias for typecheck-js"
	@echo "  ios                     Alias for build-ios-debug"
	@echo "  macos                   Alias for build-macos-debug"
	@echo "  safari                  Alias for build-safari-debug"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean                   Clean build artifacts"
	@echo "  clean-all               Deep clean including node_modules"

# JavaScript
install-js:
	@echo "Installing dependencies..."
	$(PNPM) install

_build-js:
	@echo "Building JavaScript ($(CONFIGURATION))..."
	@echo "LOGGING_VERBOSITY=$(LOGGING_VERBOSITY)"
	$(PNPM) exec tsc
	LOGGING_VERBOSITY=$(LOGGING_VERBOSITY) $(PNPM) run build

build-js-%: install-js
	$(MAKE) _build-js CONFIGURATION=$(subst build-js-,,$@)

watch-js-debug: install-js
	@echo "Starting watch mode..."
	LOGGING_VERBOSITY=$(LOGGING_VERBOSITY) $(PNPM) run build:watch

serve-js-debug: install-js
	@echo "Starting dev server..."
	LOGGING_VERBOSITY=$(LOGGING_VERBOSITY) $(PNPM) run serve

lint-js: install-js
	$(PNPM) run lint

typecheck-js: install-js
	$(PNPM) exec tsc --noEmit

# Xcode Manager
sync-xcode-groups: install-js _build-js
	@echo "Syncing file groups..."
	@$(XCODE_MGR) sync-groups

add-xcode-targets: sync-xcode-groups

bump-version-%:
	@$(XCODE_MGR) bump-version --$(subst bump-version-,,$@)

bump-build:
	@$(XCODE_MGR) bump-version --build

fix-infoplist:
	@$(XCODE_MGR) fix-infoplist

show-version:
	@$(XCODE_MGR) show-version

add-build-script:
	@$(XCODE_MGR) add-build-script

remove-build-script:
	@$(XCODE_MGR) add-build-script --remove

# Safari iOS - Internal commands
_ios-build: add-xcode-targets
	@echo "Building iOS app ($(CONFIGURATION))..."
	$(XCODEBUILD_COMMON) -scheme $(XCODE_SCHEME_IOS) clean build

_ios-run: add-xcode-targets
	@echo "Running iOS app ($(CONFIGURATION))..."
	$(XCODEBUILD_COMMON) -scheme $(XCODE_SCHEME_IOS) -destination 'platform=iOS Simulator,name=$(IOS_SIMULATOR_DEVICE)' run

_ios-archive: add-xcode-targets
	@echo "Archiving iOS app ($(CONFIGURATION))..."
	$(XCODEBUILD_COMMON) -scheme $(XCODE_SCHEME_IOS) -archivePath $(DERIVED_DATA)/$(NAME)-ios.xcarchive archive

# Safari macOS - Internal commands
_macos-build: add-xcode-targets
	@echo "Building macOS app ($(CONFIGURATION))..."
	$(XCODEBUILD_COMMON) -scheme $(XCODE_SCHEME_MACOS) clean build

_macos-run:
	@echo "Running macOS app ($(CONFIGURATION))..."
	$(OPEN) $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/$(XCODE_APP_NAME)

_macos-archive: add-xcode-targets
	@echo "Archiving macOS app ($(CONFIGURATION))..."
	$(XCODEBUILD_COMMON) -scheme $(XCODE_SCHEME_MACOS) -archivePath $(DERIVED_DATA)/$(NAME)-macos.xcarchive archive

# Pattern rule for platform builds
build-%-release: build-js-release
	$(MAKE) _$*-build CONFIGURATION=Release

build-%-debug: build-js-debug
	$(MAKE) _$*-build CONFIGURATION=Debug

build-%-preview: build-js-preview
	$(MAKE) _$*-build CONFIGURATION=Preview

# Pattern rule for platform runs
run-%-debug: build-js-debug
	$(MAKE) _$*-build _$*-run CONFIGURATION=Debug

run-%-release: build-js-release
	$(MAKE) _$*-build _$*-run CONFIGURATION=Release

run-%-preview: build-js-preview
	$(MAKE) _$*-build _$*-run CONFIGURATION=Preview

# Platform archives
archive-%: build-js-release
	$(MAKE) _$*-archive CONFIGURATION=Release

# Combined targets
build-safari-%: build-ios-% build-macos-%
	@echo "Built Safari for iOS and macOS ($*)"

# Aliases
build-js: build-js-debug
watch-js: watch-js-debug
serve-js: serve-js-debug
typecheck: typecheck-js
ios: build-ios-debug
macos: build-macos-debug
safari: build-safari-debug

# Build everything
all: build-js-release build-safari-release

# Clean
clean:
	@echo "Cleaning build artifacts..."
	$(RM) $(BUILDDIR) $(DERIVED_DATA) $(DIST_DIR) $(CACHE_DIR)

clean-all: clean
	@echo "Deep cleaning..."
	$(RM) $(NODE_MODULES) $(SCRIPTS_DIR).build/

clean-xcode: clean
	@echo "WARNING: This will remove all Xcode backups and project.pbxproj.backup files!"
	@echo "This is a destructive action and cannot be undone."
	@echo "This will also attempt to remove all DerivedData from Developer/Xcode/DerivedData"
	@read -p "Continue? (y/n): " confirm; \
	if [ "$$confirm" != "y" ]; then \
		echo "Aborting..."; \
		exit 1; \
	fi
	@echo "Cleaning Xcode artifacts..."
	$(RM) $(XCODE_PROJECT).pbxproj.backup
	$(RM) "/Applications/Xcode.app/Contents/Developer/Xcode/DerivedData"


prepare:
	$(MKDIR) $(BUILDDIR) $(DERIVED_DATA)

.PHONY: help install-js _build-js lint-js typecheck-js watch-js-debug serve-js-debug \
	sync-xcode-groups add-xcode-targets fix-infoplist show-version add-build-script remove-build-script \
	_ios-build _ios-run _ios-archive _macos-build _macos-run _macos-archive \
	build-js watch-js serve-js typecheck ios macos safari all clean clean-all prepare
