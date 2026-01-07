#!/usr/bin/env bash
#
# issue-templates.sh - GitHub issue template management for claw
# Creates and manages .github/ISSUE_TEMPLATE/ files across repos
#

set -euo pipefail

# Template directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUE_TEMPLATES_DIR="${SCRIPT_DIR}/../templates/github-issue-templates"

# Available templates
AVAILABLE_TEMPLATES=(
    "bug-report:Bug Report:Report bugs and unexpected behavior"
    "feature-request:Feature Request:Suggest new features"
    "claude-ready:Claude Ready Task:Tasks ready for Claude Code (/plan-day)"
    "tech-debt:Technical Debt:Track refactoring and tech debt"
)

# ============================================================================
# Template Functions
# ============================================================================

# List available templates
list_available_templates() {
    echo "Available GitHub issue templates:"
    echo ""
    for entry in "${AVAILABLE_TEMPLATES[@]}"; do
        local id="${entry%%:*}"
        local rest="${entry#*:}"
        local name="${rest%%:*}"
        local desc="${rest#*:}"
        echo "  ${id}"
        echo "    ${name} - ${desc}"
        echo ""
    done
}

# Check if gh CLI is available and authenticated
check_gh_auth() {
    if ! command -v gh &>/dev/null; then
        echo "Error: gh CLI not found. Install from https://cli.github.com/" >&2
        return 1
    fi

    if ! gh auth status &>/dev/null 2>&1; then
        echo "Error: gh CLI not authenticated. Run 'gh auth login'" >&2
        return 1
    fi

    return 0
}

# Get template content by ID
get_template_content() {
    local id="$1"
    local template_file="${ISSUE_TEMPLATES_DIR}/${id}.md"

    if [[ ! -f "$template_file" ]]; then
        echo "Error: Template '${id}' not found" >&2
        return 1
    fi

    cat "$template_file"
}

# Install templates to a repo
install_templates_to_repo() {
    local repo="$1"
    shift
    local templates=("$@")

    if [[ ${#templates[@]} -eq 0 ]]; then
        echo "No templates selected"
        return 0
    fi

    echo "Installing templates to ${repo}..."
    echo ""

    # Clone repo to temp dir
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" EXIT

    if ! gh repo clone "$repo" "$tmp_dir" -- --depth 1 2>/dev/null; then
        echo "Error: Failed to clone ${repo}" >&2
        return 1
    fi

    # Create .github/ISSUE_TEMPLATE directory
    mkdir -p "${tmp_dir}/.github/ISSUE_TEMPLATE"

    # Copy selected templates
    local installed=0
    for template_id in "${templates[@]}"; do
        local src="${ISSUE_TEMPLATES_DIR}/${template_id}.md"
        local dest="${tmp_dir}/.github/ISSUE_TEMPLATE/${template_id}.md"

        if [[ -f "$src" ]]; then
            cp "$src" "$dest"
            echo "  ✓ ${template_id}.md"
            ((installed++))
        else
            echo "  ✗ ${template_id}.md (not found)"
        fi
    done

    if [[ $installed -eq 0 ]]; then
        echo "No templates installed"
        return 0
    fi

    # Commit and push
    cd "$tmp_dir"
    git add .github/ISSUE_TEMPLATE/

    if git diff --cached --quiet; then
        echo ""
        echo "No changes to commit (templates may already exist)"
        return 0
    fi

    git commit -m "Add GitHub issue templates

Installed via claw templates command.
Templates: ${templates[*]}

🤖 Generated with claw (https://github.com/bis-code/claw)"

    if git push origin HEAD; then
        echo ""
        echo "✓ Templates installed to ${repo}"
    else
        echo ""
        echo "Error: Failed to push changes" >&2
        return 1
    fi
}

# Interactive template selection
select_templates_interactive() {
    echo "Select templates to install (space to toggle, enter to confirm):"
    echo ""

    local selected=()
    local i=0

    # Simple selection - list templates and ask for comma-separated IDs
    for entry in "${AVAILABLE_TEMPLATES[@]}"; do
        local id="${entry%%:*}"
        local rest="${entry#*:}"
        local name="${rest%%:*}"
        ((i++))
        echo "  $i) ${id} - ${name}"
    done

    echo ""
    echo "  a) All templates"
    echo "  q) Cancel"
    echo ""
    read -p "Enter choices (e.g., 1,3 or 'a' for all): " choice

    if [[ "$choice" == "q" ]]; then
        return 1
    fi

    if [[ "$choice" == "a" ]]; then
        for entry in "${AVAILABLE_TEMPLATES[@]}"; do
            selected+=("${entry%%:*}")
        done
    else
        IFS=',' read -ra choices <<< "$choice"
        for c in "${choices[@]}"; do
            c=$(echo "$c" | tr -d ' ')
            if [[ "$c" =~ ^[0-9]+$ ]] && [[ $c -ge 1 ]] && [[ $c -le ${#AVAILABLE_TEMPLATES[@]} ]]; then
                local entry="${AVAILABLE_TEMPLATES[$((c-1))]}"
                selected+=("${entry%%:*}")
            fi
        done
    fi

    if [[ ${#selected[@]} -eq 0 ]]; then
        echo "No templates selected"
        return 1
    fi

    echo "${selected[@]}"
}

# Main templates command handler
handle_templates_command() {
    local subcommand="${1:-}"
    shift 2>/dev/null || true

    case "$subcommand" in
        list|ls)
            list_available_templates
            ;;
        install)
            check_gh_auth || return 1

            local repo="${1:-}"
            shift 2>/dev/null || true

            if [[ -z "$repo" ]]; then
                # Try to get current repo
                repo=$(get_current_repo 2>/dev/null || echo "")
                if [[ -z "$repo" ]]; then
                    echo "Usage: claw templates install <owner/repo> [template-ids...]"
                    echo ""
                    echo "Or run from within a git repo with GitHub remote"
                    return 1
                fi
                echo "Using current repo: ${repo}"
                echo ""
            fi

            local templates=("$@")

            if [[ ${#templates[@]} -eq 0 ]]; then
                # Interactive selection
                local selection
                selection=$(select_templates_interactive) || return 1
                read -ra templates <<< "$selection"
            fi

            install_templates_to_repo "$repo" "${templates[@]}"
            ;;
        ""|--help|-h)
            cat << 'EOF'
claw templates - Manage GitHub issue templates

Usage:
  claw templates list                     List available templates
  claw templates install <repo> [ids...]  Install templates to a repo
  claw templates install                  Install to current repo (interactive)

Available templates:
  bug-report      Bug Report template
  feature-request Feature Request template
  claude-ready    Claude Ready task (for /plan-day)
  tech-debt       Technical Debt tracking

Examples:
  claw templates list
  claw templates install myorg/myrepo
  claw templates install myorg/myrepo bug-report claude-ready
  claw templates install  # Current repo, interactive selection

The claude-ready template creates issues that appear in /plan-day.
EOF
            ;;
        *)
            echo "Unknown templates command: $subcommand"
            echo "Run 'claw templates --help' for usage"
            return 1
            ;;
    esac
}
