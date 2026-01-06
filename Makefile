# Makefile for claw - Claude Automated Workflow
# Run 'make help' for available targets

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

# Paths
BATS := ./tests/bats/bin/bats
PROJECT_ROOT := $(shell pwd)

#==============================================================================
# Help
#==============================================================================
.PHONY: help
help: ## Show this help message
	@echo "claw - Claude Automated Workflow"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick start:"
	@echo "  make setup     # Install all dependencies"
	@echo "  make test      # Run all tests"

#==============================================================================
# Setup Targets
#==============================================================================
.PHONY: setup setup-bats setup-gh setup-uv setup-leann check-deps

setup: setup-bats setup-gh setup-uv setup-leann ## Install all dependencies
	@echo ""
	@echo "$(GREEN)✓ All dependencies installed$(NC)"
	@$(MAKE) check-deps

setup-bats: ## Install BATS testing framework
	@echo "$(YELLOW)→ Setting up BATS...$(NC)"
	@if [ ! -d "tests/bats" ]; then \
		git clone --depth 1 https://github.com/bats-core/bats-core.git tests/bats 2>/dev/null || \
			(echo "$(RED)✗ Failed to clone bats-core$(NC)" && exit 1); \
	fi
	@if [ ! -d "tests/test_helper/bats-support" ]; then \
		git clone --depth 1 https://github.com/bats-core/bats-support.git tests/test_helper/bats-support 2>/dev/null || \
			(echo "$(RED)✗ Failed to clone bats-support$(NC)" && exit 1); \
	fi
	@if [ ! -d "tests/test_helper/bats-assert" ]; then \
		git clone --depth 1 https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert 2>/dev/null || \
			(echo "$(RED)✗ Failed to clone bats-assert$(NC)" && exit 1); \
	fi
	@echo "$(GREEN)✓ BATS installed$(NC)"

setup-gh: ## Install GitHub CLI (if not present)
	@echo "$(YELLOW)→ Checking GitHub CLI...$(NC)"
	@if command -v gh &>/dev/null; then \
		echo "$(GREEN)✓ gh CLI already installed$(NC)"; \
	else \
		echo "Installing gh CLI..."; \
		if [[ "$$(uname)" == "Darwin" ]]; then \
			brew install gh 2>/dev/null || (echo "$(RED)✗ Install gh manually: https://cli.github.com$(NC)" && exit 1); \
		elif [[ "$$(uname)" == "Linux" ]]; then \
			curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null && \
			echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
			sudo apt update && sudo apt install gh -y 2>/dev/null || \
			(echo "$(RED)✗ Install gh manually: https://cli.github.com$(NC)" && exit 1); \
		else \
			echo "$(RED)✗ Install gh manually: https://cli.github.com$(NC)" && exit 1; \
		fi; \
		echo "$(GREEN)✓ gh CLI installed$(NC)"; \
	fi

setup-uv: ## Install uv (Python package manager)
	@echo "$(YELLOW)→ Checking uv...$(NC)"
	@if command -v uv &>/dev/null; then \
		echo "$(GREEN)✓ uv already installed$(NC)"; \
	else \
		echo "Installing uv..."; \
		curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null || \
			(echo "$(RED)✗ Failed to install uv$(NC)" && exit 1); \
		echo "$(GREEN)✓ uv installed$(NC)"; \
	fi

setup-leann: ## Install LEANN (semantic search)
	@echo "$(YELLOW)→ Checking LEANN...$(NC)"
	@if command -v leann &>/dev/null; then \
		echo "$(GREEN)✓ LEANN already installed$(NC)"; \
	else \
		echo "Installing LEANN..."; \
		if command -v uv &>/dev/null; then \
			uv tool install leann 2>/dev/null || \
				(echo "$(RED)✗ Failed to install LEANN$(NC)" && exit 1); \
		else \
			echo "$(RED)✗ uv required for LEANN installation$(NC)"; \
			echo "Run 'make setup-uv' first"; \
			exit 1; \
		fi; \
		echo "$(GREEN)✓ LEANN installed$(NC)"; \
	fi

check-deps: ## Check status of all dependencies
	@echo ""
	@echo "Dependency Status:"
	@echo "─────────────────────────────────"
	@if [ -f "$(BATS)" ]; then \
		echo "  $(GREEN)✓$(NC) BATS"; \
	else \
		echo "  $(RED)✗$(NC) BATS (run 'make setup-bats')"; \
	fi
	@if command -v gh &>/dev/null; then \
		if gh auth status &>/dev/null; then \
			echo "  $(GREEN)✓$(NC) gh CLI (authenticated)"; \
		else \
			echo "  $(YELLOW)!$(NC) gh CLI (not authenticated - run 'gh auth login')"; \
		fi; \
	else \
		echo "  $(RED)✗$(NC) gh CLI (run 'make setup-gh')"; \
	fi
	@if command -v uv &>/dev/null; then \
		echo "  $(GREEN)✓$(NC) uv"; \
	else \
		echo "  $(RED)✗$(NC) uv (run 'make setup-uv')"; \
	fi
	@if command -v leann &>/dev/null; then \
		echo "  $(GREEN)✓$(NC) LEANN"; \
	else \
		echo "  $(RED)✗$(NC) LEANN (run 'make setup-leann')"; \
	fi
	@echo ""

#==============================================================================
# Test Targets
#==============================================================================
.PHONY: test test-unit test-integration test-external test-all test-ci

test: ensure-bats ## Run core tests (unit + integration)
	@echo "$(YELLOW)→ Running core tests...$(NC)"
	@$(BATS) tests/detect_project.bats tests/integration.bats tests/project_types.bats tests/agents.bats tests/edge_cases.bats
	@echo "$(GREEN)✓ Core tests passed$(NC)"

test-unit: ensure-bats ## Run unit tests only
	@echo "$(YELLOW)→ Running unit tests...$(NC)"
	@$(BATS) tests/detect_project.bats tests/project_types.bats tests/agents.bats
	@echo "$(GREEN)✓ Unit tests passed$(NC)"

test-integration: ensure-bats ## Run integration tests only
	@echo "$(YELLOW)→ Running integration tests...$(NC)"
	@$(BATS) tests/integration.bats tests/edge_cases.bats
	@echo "$(GREEN)✓ Integration tests passed$(NC)"

test-external: ensure-bats ## Run external dependency tests (gh, LEANN)
	@echo "$(YELLOW)→ Running external dependency tests...$(NC)"
	@$(BATS) tests/leann.bats tests/multi_repo.bats tests/external_deps.bats
	@echo "$(GREEN)✓ External dependency tests passed$(NC)"

test-all: ensure-bats ## Run ALL tests including external dependencies
	@echo "$(YELLOW)→ Running all tests...$(NC)"
	@$(BATS) tests/
	@echo "$(GREEN)✓ All tests passed$(NC)"

test-ci: ## Run tests suitable for CI (skips tests requiring auth)
	@echo "$(YELLOW)→ Running CI tests...$(NC)"
	@CI=true $(BATS) tests/
	@echo "$(GREEN)✓ CI tests passed$(NC)"

ensure-bats:
	@if [ ! -f "$(BATS)" ]; then \
		echo "$(YELLOW)BATS not found. Installing...$(NC)"; \
		$(MAKE) setup-bats; \
	fi

#==============================================================================
# Development Targets
#==============================================================================
.PHONY: lint clean install uninstall

lint: ## Run shellcheck on all bash scripts
	@echo "$(YELLOW)→ Running shellcheck...$(NC)"
	@if command -v shellcheck &>/dev/null; then \
		shellcheck bin/claw lib/*.sh install.sh tests/setup_tests.sh || true; \
		echo "$(GREEN)✓ Lint complete$(NC)"; \
	else \
		echo "$(RED)✗ shellcheck not installed$(NC)"; \
		echo "Install with: brew install shellcheck"; \
	fi

clean: ## Remove test artifacts and temporary files
	@echo "$(YELLOW)→ Cleaning up...$(NC)"
	@rm -rf tests/bats tests/test_helper/bats-support tests/test_helper/bats-assert
	@rm -rf /tmp/claw-test-*
	@echo "$(GREEN)✓ Cleaned$(NC)"

install: ## Install claw globally
	@echo "$(YELLOW)→ Installing claw...$(NC)"
	@./install.sh
	@echo "$(GREEN)✓ Installed$(NC)"

uninstall: ## Uninstall claw
	@echo "$(YELLOW)→ Uninstalling claw...$(NC)"
	@rm -f /usr/local/bin/claw 2>/dev/null || sudo rm -f /usr/local/bin/claw
	@echo "$(GREEN)✓ Uninstalled$(NC)"

#==============================================================================
# CI/CD Targets
#==============================================================================
.PHONY: ci-setup ci-test

ci-setup: setup-bats ## CI-only setup (minimal dependencies)
	@echo "$(GREEN)✓ CI setup complete$(NC)"

ci-test: ci-setup test-ci ## Full CI pipeline
	@echo "$(GREEN)✓ CI pipeline complete$(NC)"
