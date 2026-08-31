# Atril — development targets.
# Run `make help` for the annotated list.

FLUTTER ?= flutter
DART    ?= dart

# The Quire checkout the contract is vendored from. Phase 1 is what reads it.
QUIRE   ?= ../quire

# The entry point `run-linux` and `run-web` start. Phase 5 adds
# lib/main_development.dart — the one pointed at `make dev-up` next door — and
# makes it the default here; until then there is only one.
ENTRY   ?= lib/main.dart

# `flutter build macos` and `flutter build windows` need the host they target,
# so `build-all` builds what this machine can and leaves the rest to the six
# jobs in .github/workflows/ci.yml.
HOST    := $(shell uname -s)
ifeq ($(HOST),Darwin)
HOST_TARGETS := web android ios macos
else ifeq ($(findstring MINGW,$(HOST)),MINGW)
HOST_TARGETS := web windows
else
HOST_TARGETS := web android linux
endif

.DEFAULT_GOAL := help

## help: list the available targets
.PHONY: help
help:
	@grep -hE '^## ' $(MAKEFILE_LIST) | sed -E 's/^## ([a-z0-9-]+): /\1\t/' | awk -F '\t' '{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# --- code --------------------------------------------------------------------

## deps: resolve the pub dependencies
.PHONY: deps
deps:
	$(FLUTTER) pub get

## proto: refresh the vendored contract from the Quire checkout (QUIRE=../quire)
.PHONY: proto
proto:
	@echo "not yet: phase 1 vendors proto/quire/v1 and implements this target" >&2
	@exit 1

## gen: regenerate everything that is generated and committed
.PHONY: gen
gen:
	@echo "not yet: phase 1 wires protoc-gen-dart into this target" >&2
	@exit 1

## fmt: format the Dart sources in place
.PHONY: fmt
fmt:
	$(DART) format .

# --- checks ------------------------------------------------------------------

## analyze: the formatter and the analyzer, as CI runs them
.PHONY: analyze
analyze:
	$(DART) format --output=none --set-exit-if-changed .
	$(FLUTTER) analyze

## test: the unit and widget tests
.PHONY: test
test:
	$(FLUTTER) test

# --- running -----------------------------------------------------------------

## run-linux: run against the local federation over the native gRPC lane
.PHONY: run-linux
run-linux:
	$(FLUTTER) run -d linux -t $(ENTRY)

## run-web: run against the local federation over the gRPC-Web lane
.PHONY: run-web
run-web:
	$(FLUTTER) run -d chrome -t $(ENTRY)

# --- building ----------------------------------------------------------------

## build-all: build every target this host can build (CI builds all six)
.PHONY: build-all
build-all: $(addprefix build-,$(HOST_TARGETS))
	@echo "built: $(HOST_TARGETS) — the rest are on CI"

.PHONY: build-web build-android build-linux build-macos build-ios build-windows
build-web:
	$(FLUTTER) build web
build-android:
	$(FLUTTER) build apk --debug
build-linux:
	$(FLUTTER) build linux --debug
build-macos:
	$(FLUTTER) build macos --debug
build-ios:
	$(FLUTTER) build ios --debug --no-codesign
build-windows:
	$(FLUTTER) build windows --debug

## clean: remove the build output
.PHONY: clean
clean:
	$(FLUTTER) clean
