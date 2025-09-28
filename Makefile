.PHONY: help install install-ubuntu install-mac lint lint-shell lint-python smoke docs

SHELL := /bin/bash
REPO_ROOT := $(CURDIR)
SHELLCHECK ?= shellcheck
PYTHON ?= python3

help:
	@printf "Available targets:\n"
	@printf "  make install          # Run unattended Ubuntu/Debian setup\n"
	@printf "  make install-ubuntu   # Run full Ubuntu setup script\n"
	@printf "  make install-mac      # Run macOS setup script\n"
	@printf "  make lint             # Run shell and python lint checks\n"
	@printf "  make smoke            # Execute smoke tests (zsh, nvim, tmux)\n"
	@printf "  make docs             # Open docs folder in EDITOR for updates\n"

install:
	bash $(REPO_ROOT)/setup_noninteractive.sh

install-ubuntu:
	bash $(REPO_ROOT)/setup_ubuntu.sh

install-mac:
	bash $(REPO_ROOT)/setup_mac.sh

lint: lint-shell lint-python

lint-shell:
	$(SHELLCHECK) -x setup_noninteractive.sh setup_ubuntu.sh scripts/bootstrap/common.sh scripts/smoke/run.sh

lint-python:
	$(PYTHON) -m compileall custom-tools/pytools/src/pytools

smoke:
	bash $(REPO_ROOT)/scripts/smoke/run.sh

docs:
	${EDITOR:-nvim} $(REPO_ROOT)/docs/README.md
