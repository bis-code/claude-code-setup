# Test Coverage Analysis

## Current Status: 164 tests passing

## Test Files

| File | Tests | Focus |
|------|-------|-------|
| `detect_project.bats` | 14 | Project type detection unit tests |
| `integration.bats` | 14 | CLI integration tests |
| `project_types.bats` | 32 | All project type detection |
| `agents.bats` | 41 | Agent prompts and roster |
| `leann.bats` | 18 | LEANN integration |
| `multi_repo.bats` | 16 | Multi-repo functionality |
| `edge_cases.bats` | 20 | Error handling and edge cases |
| `external_deps.bats` | 19 | External dependency tests (gh, LEANN, uv) |

## Coverage by Module

### lib/detect-project.sh

| Function | Tested | Notes |
|----------|--------|-------|
| `detect_project_type` | ✅ Yes | All project types covered |
| `detect_monorepo_packages` | ✅ Yes | pnpm, npm, lerna, turbo, nx, cargo |
| `get_agents_for_type` | ✅ Yes | All project types |
| `detect_multi_repo` | ✅ Yes | Sibling detection, config reading |
| `fetch_multi_repo_issues` | ✅ Yes | Real gh CLI tested in external_deps.bats |
| `detect_cross_repo_dependencies` | ✅ Yes | Returns empty array |
| `format_multi_repo_issues_for_brainstorm` | ❌ No | UI formatting |
| `create_multi_repo_config` | ✅ Yes | Creates config file |
| `print_detection_summary` | ✅ Yes | Output structure |

### lib/agents.sh

| Function | Tested | Notes |
|----------|--------|-------|
| `get_agent_prompt` | ✅ Yes | All agents tested |
| `get_agents_for_type` | ✅ Yes | All project types |
| `list_agents` | ✅ Yes | Categories and agents |
| `get_orchestrator_prompt` | ✅ Yes | Content verified |
| `get_debate_prompt` | ✅ Yes | Agent name included |

### lib/leann-setup.sh

| Function | Tested | Notes |
|----------|--------|-------|
| `is_leann_installed` | ✅ Yes | Conditional skip |
| `is_uv_installed` | ✅ Yes | Conditional skip |
| `install_leann` | ✅ Yes | Tested in external_deps.bats (if uv available) |
| `setup_leann_mcp` | ❌ No | Requires claude CLI |
| `build_index` | ✅ Yes | Real LEANN tested in external_deps.bats |
| `search_index` | ✅ Yes | Real LEANN tested in external_deps.bats |
| `leann_status` | ✅ Yes | Output verified |
| `get_leann_agent_instructions` | ✅ Yes | Content verified |
| `inject_leann_instructions` | ✅ Yes | File modification |
| `leann_cmd` | ✅ Yes | Subcommand routing |
| `fallback_search` | ✅ Yes | Non-LEANN search |

### bin/claw

| Command | Tested | Notes |
|---------|--------|-------|
| `help` | ✅ Yes | Content verified |
| `version` | ✅ Yes | Format verified |
| `init` | ✅ Yes | All presets, auto-detect |
| `detect` | ✅ Yes | All project types |
| `upgrade` | ✅ Partial | Same as init --force |
| `check` | ❌ No | Placeholder |
| `status` | ✅ Partial | Same as detect |
| `leann *` | ✅ Yes | All subcommands |
| `multi-repo *` | ✅ Yes | All subcommands |
| `agents *` | ✅ Yes | list, spawn |

## Project Types Tested

| Type | Detection Method | Test |
|------|-----------------|------|
| game-unity | Assets/, ProjectSettings/ | ✅ |
| game-godot | project.godot | ✅ |
| saas | Next.js + Stripe/Auth | ✅ |
| web | React/Vue/Svelte/Nuxt | ✅ |
| api | Express/Fastify/NestJS | ✅ |
| library | main without start | ✅ |
| cli | bin in package.json or cmd/ | ✅ |
| web3 | hardhat.config.* or foundry.toml | ✅ |
| mobile | react-native/expo | ✅ |
| desktop | electron/tauri | ✅ |
| data-ml | torch/tensorflow/sklearn | ✅ |
| unknown | No markers | ✅ |

## Agents Tested

### General Purpose
- ✅ senior-dev
- ✅ product
- ✅ cto
- ✅ qa
- ✅ ux
- ✅ security

### Game Development
- ✅ gameplay-programmer
- ✅ systems-programmer
- ✅ tools-programmer
- ✅ technical-artist

### Specialized
- ✅ data-scientist
- ✅ mlops
- ✅ api-designer
- ✅ docs
- ✅ auditor
- ✅ mobile-specialist
- ✅ desktop-specialist

## Edge Cases Tested

- ✅ Unknown commands
- ✅ Invalid presets
- ✅ Missing arguments
- ✅ Symlinks
- ✅ Paths with spaces
- ✅ Empty/malformed config files
- ✅ Existing .claude directory
- ✅ Library loading
- ✅ Regression: unbound variables

## External Dependencies Tested

The following are tested in `external_deps.bats` (skipped if dependencies unavailable):

### GitHub CLI (gh)
- ✅ Installation check
- ✅ Authentication status
- ✅ Repository listing
- ✅ Issue fetching from repo
- ✅ PR fetching from repo
- ✅ Multi-repo issue aggregation

### LEANN
- ✅ Installation check
- ✅ Index listing
- ✅ Index building
- ✅ Semantic search
- ✅ Index removal

### uv (Python package manager)
- ✅ Installation check
- ✅ Version check

## Not Tested

- LEANN MCP setup (requires claude CLI)
- sudo installation (requires privileges)

## Running Tests

```bash
# Quick start with Makefile
make setup      # Install all dependencies
make test       # Run core tests
make test-all   # Run all tests including external deps

# Or manually:
./tests/setup_tests.sh

# Run all tests
bats tests/

# Run specific test file
bats tests/project_types.bats

# Run external dependency tests only
bats tests/external_deps.bats

# Run with verbose output
bats --verbose-run tests/
```

## CI Pipeline

Tests are automatically run via GitHub Actions on:
- Push to main branch
- Pull requests to main branch

The CI pipeline:
1. Runs on both Ubuntu and macOS
2. Installs uv and LEANN for external dependency tests
3. Executes all unit, integration, and external tests
4. Runs shellcheck linting
5. Tests skip gracefully if dependencies fail to install
