#!/usr/bin/env bash
# VeloDB Agent Skills Installer v4.0
# Install, update, or uninstall skills at project or global level
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; YELLOW='\033[0;33m'
CHECK="${GREEN}✓${RESET}"; CROSS="${RED}✗${RESET}"; ARROW="${CYAN}▸${RESET}"; DIAMOND="${MAGENTA}◆${RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
SKILLS=("velodb-architecture-advisor" "velodb-best-practices" "velocli-cloud")
VERSION="4.0.0"

# Defaults: project-level, install action
SCOPE="project"  # project | global
ACTION="install"  # install | uninstall | update
TARGET_AGENT=""
CUSTOM_PATH=""

# Agent config directory names (relative — prefixed with $HOME or $PWD depending on scope)
declare -A AGENT_SUBDIRS=(
    [claude]=".claude/skills"
    [antigravity]=".agents/skills"
    [cursor]=".cursor/skills"
    [windsurf]=".windsurf/skills"
    [codex]=".codex/skills"
    [gemini]=".gemini/skills"
    [copilot]=".github/copilot/skills"
    [kiro]=".kiro/skills"
)

resolve_dir() {
    local agent="$1"
    local subdir="${AGENT_SUBDIRS[$agent]}"
    if [[ "$SCOPE" == "global" ]]; then
        echo "$HOME/$subdir"
    else
        echo "$(pwd)/$subdir"
    fi
}

show_banner() {
    echo; printf "${BLUE}"
    cat << 'B'
    ╭─────────────────────────────────────────╮
    │   ██╗   ██╗███████╗██╗      ██████╗     │
    │   ██║   ██║██╔════╝██║     ██╔═══██╗    │
    │   ██║   ██║█████╗  ██║     ██║   ██║    │
    │   ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║    │
    │    ╚████╔╝ ███████╗███████╗╚██████╔╝    │
    │     ╚═══╝  ╚══════╝╚══════╝ ╚═════╝     │
    │         Agent Skills v4.0               │
    ╰─────────────────────────────────────────╯
B
    printf "${RESET}\n"
    printf "  ${DIM}3 skills · 37 rules · 10 industry examples · CLI diagnostics${RESET}\n\n"
    printf "  ${WHITE}Skills:${RESET}\n"
    printf "    ${GREEN}▸${RESET} velodb-architecture-advisor  ${DIM}— design & sizing${RESET}\n"
    printf "    ${GREEN}▸${RESET} velodb-best-practices        ${DIM}— DDL rules & query diagnosis${RESET}\n"
    printf "    ${GREEN}▸${RESET} velocli-cloud                ${DIM}— Cloud operations${RESET}\n\n"
}

progress_bar() {
    local c=$1 t=$2 pct=$(($1*100/$2)) f=$(($1*30/$2)) e=$((30-$1*30/$2)) b=""
    for((i=0;i<f;i++));do b+="█";done; for((i=0;i<e;i++));do b+="░";done
    printf "\r  ${DIM}[${RESET}${GREEN}%s${RESET}${DIM}]${RESET} ${WHITE}%3d%%${RESET}" "$b" "$pct"
}

# ─── Install ────────────────────────────────────────────────────────────────

install_skill_to_dir() {
    local skill_name="$1" target_base="$2"
    local src="$SKILLS_DIR/$skill_name"
    local dest="$target_base/$skill_name"

    if [[ ! -d "$src" ]]; then
        printf "  ${CROSS} ${skill_name} source not found at ${src}\n"
        return 1
    fi

    # Clean previous install
    [[ -d "$dest" ]] && rm -rf "$dest"
    [[ -L "$dest" ]] && rm -f "$dest"

    mkdir -p "$dest"
    [[ -d "$src/references" ]] && mkdir -p "$dest/references"

    local fs=() rs=()
    for f in "$src"/*.md; do [[ -f "$f" ]] && fs+=("$f"); done
    if [[ -d "$src/references" ]]; then
        for f in "$src/references"/*.md; do [[ -f "$f" ]] && rs+=("$f"); done
    fi
    local t=$((${#fs[@]}+${#rs[@]})) c=0

    for f in "${fs[@]}"; do cp "$f" "$dest/"; c=$((c+1)); progress_bar $c $t; sleep 0.01; done
    for f in "${rs[@]}"; do cp "$f" "$dest/references/"; c=$((c+1)); progress_bar $c $t; sleep 0.01; done
    echo
    printf "  ${CHECK} ${CYAN}%s${RESET} → %s ${DIM}(%d files)${RESET}\n" "$skill_name" "$dest" "$t"
}

install_all_skills_to_dir() {
    local target_base="$1"
    for skill in "${SKILLS[@]}"; do
        install_skill_to_dir "$skill" "$target_base"
    done
    # Write version marker
    echo "$VERSION" > "$target_base/.velodb-skills-version"
}

# ─── Uninstall ──────────────────────────────────────────────────────────────

uninstall_skills_from_dir() {
    local target_base="$1"
    local removed=0
    for skill in "${SKILLS[@]}"; do
        local dest="$target_base/$skill"
        if [[ -d "$dest" ]] || [[ -L "$dest" ]]; then
            rm -rf "$dest"
            printf "  ${CHECK} Removed ${CYAN}%s${RESET} from %s\n" "$skill" "$target_base"
            removed=$((removed+1))
        fi
    done
    # Remove version marker
    rm -f "$target_base/.velodb-skills-version"
    if [[ $removed -eq 0 ]]; then
        printf "  ${DIM}○ No VeloDB skills found in %s${RESET}\n" "$target_base"
    else
        printf "\n  ${CHECK} Removed ${WHITE}%d${RESET} skill(s)\n" "$removed"
    fi
}

# ─── Update ─────────────────────────────────────────────────────────────────

update_skills_in_dir() {
    local target_base="$1"
    local has_skills=false
    for skill in "${SKILLS[@]}"; do
        [[ -d "$target_base/$skill" ]] && has_skills=true && break
    done

    if [[ "$has_skills" == false ]]; then
        printf "  ${DIM}○ No VeloDB skills found in %s — nothing to update${RESET}\n" "$target_base"
        return
    fi

    local old_version="unknown"
    [[ -f "$target_base/.velodb-skills-version" ]] && old_version="$(cat "$target_base/.velodb-skills-version")"
    printf "  ${ARROW} Updating ${DIM}(%s → %s)${RESET}\n" "$old_version" "$VERSION"
    install_all_skills_to_dir "$target_base"
}

# ─── Agent detection ────────────────────────────────────────────────────────

detect_agents() {
    local found=()
    for name in "${!AGENT_SUBDIRS[@]}"; do
        local dir
        dir="$(resolve_dir "$name")"
        local parent="$(dirname "$dir")"
        [[ -d "$parent" ]] && found+=("$name")
    done
    echo "${found[@]}"
}

run_on_all_detected() {
    local action_fn="$1"
    local agents=($(detect_agents))
    if [[ ${#agents[@]} -eq 0 ]]; then
        printf "  ${CROSS} No agents detected. Use ${WHITE}--agent <name>${RESET} or ${WHITE}--path DIR${RESET}.\n"
        return 1
    fi
    local scope_label="project"
    [[ "$SCOPE" == "global" ]] && scope_label="global (~)"
    printf "  ${DIAMOND} Detected ${WHITE}${#agents[@]}${RESET} agent(s) ${DIM}[%s]${RESET}: ${CYAN}%s${RESET}\n\n" "$scope_label" "${agents[*]}"
    for name in "${agents[@]}"; do
        local dir
        dir="$(resolve_dir "$name")"
        printf "\n  ${BOLD}[%s]${RESET} %s\n" "$name" "$dir"
        $action_fn "$dir"
    done
}

run_on_agent() {
    local agent="$1" action_fn="$2"
    if [[ -z "${AGENT_SUBDIRS[$agent]+x}" ]]; then
        printf "  ${CROSS} Unknown agent: ${WHITE}%s${RESET}\n" "$agent"
        printf "  ${DIM}Supported: %s${RESET}\n" "${!AGENT_SUBDIRS[*]}"
        exit 1
    fi
    local dir
    dir="$(resolve_dir "$agent")"
    printf "\n  ${BOLD}[%s]${RESET} %s\n" "$agent" "$dir"
    $action_fn "$dir"
}

# ─── velocli ────────────────────────────────────────────────────────────────

install_velocli() {
    echo
    printf "  ${DIAMOND} ${BOLD}Installing velocli CLI${RESET}\n\n"
    if command -v velocli >/dev/null 2>&1; then
        printf "  ${CHECK} velocli already installed: ${CYAN}$(velocli --version)${RESET}\n"
    elif command -v npm >/dev/null 2>&1; then
        printf "  ${ARROW} npm install -g @velodb/velocli\n"
        npm install -g @velodb/velocli 2>&1 | tail -1
        printf "  ${CHECK} Installed: ${CYAN}$(velocli --version)${RESET}\n"
    elif command -v npx >/dev/null 2>&1; then
        printf "  ${YELLOW}!${RESET} npm not found but npx available. Run via: ${WHITE}npx velocli <command>${RESET}\n"
        printf "    Or install globally: ${WHITE}npm install -g @velodb/velocli${RESET}\n"
    else
        printf "  ${CROSS} npm/npx not found. Install Node.js first, then:\n"
        printf "    ${WHITE}npm install -g @velodb/velocli${RESET}\n"
    fi
}

maybe_ask_velocli() {
    echo
    if command -v velocli >/dev/null 2>&1; then
        printf "  ${CHECK} velocli already installed: ${CYAN}$(velocli --version)${RESET}\n"
    elif command -v npx >/dev/null 2>&1 && npx velocli --version >/dev/null 2>&1; then
        printf "  ${CHECK} velocli available via npx: ${CYAN}$(npx velocli --version 2>/dev/null)${RESET}\n"
    else
        printf "  ${DIAMOND} ${BOLD}Install velocli CLI?${RESET} ${DIM}(optional — enables query profiling & Cloud management)${RESET}\n"
        printf "  ${ARROW} Install velocli? ${DIM}[y/N]:${RESET} "; read -r yc
        case "${yc:-n}" in
            [yY]*) install_velocli ;;
            *) printf "  ${DIM}○ Skipped. Install later: npm install -g @velodb/velocli${RESET}\n" ;;
        esac
    fi
}

# ─── Summaries ──────────────────────────────────────────────────────────────

show_install_summary() {
    echo; printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
    printf "  ${CHECK} ${BOLD}Installation complete!${RESET}\n\n"
    printf "  ${DIAMOND} ${WHITE}What's included:${RESET}\n"
    printf "     ${DIM}├─${RESET} ${BOLD}velodb-architecture-advisor${RESET}\n"
    printf "     ${DIM}│  ${RESET} ${DIM}8 decision frameworks · 10 industry examples${RESET}\n"
    printf "     ${DIM}├─${RESET} ${BOLD}velodb-best-practices${RESET}\n"
    printf "     ${DIM}│  ${RESET} ${DIM}37 rules · 7 use case templates · 5 DDL templates${RESET}\n"
    printf "     ${DIM}└─${RESET} ${BOLD}velocli-cloud${RESET}\n"
    printf "        ${DIM}Cloud onboarding · cluster lifecycle · billing · networking${RESET}\n\n"

    if command -v velocli >/dev/null 2>&1; then
        printf "  ${CHECK} velocli: ${CYAN}$(velocli --version)${RESET}\n"
    elif command -v npx >/dev/null 2>&1 && npx velocli --version >/dev/null 2>&1; then
        printf "  ${CHECK} velocli (via npx): ${CYAN}$(npx velocli --version 2>/dev/null)${RESET}\n"
    else
        printf "  ${DIM}○${RESET} velocli: not installed ${DIM}(optional)${RESET}\n"
        printf "    Install: ${WHITE}npm install -g @velodb/velocli${RESET}\n"
    fi

    echo
    printf "  ${DIAMOND} ${WHITE}Try it:${RESET}\n"
    printf "     ${DIM}\"Design a table for real-time fleet tracking analytics\"${RESET}\n"
    printf "     ${DIM}\"Review this CREATE TABLE for best practices\"${RESET}\n"
    printf "     ${DIM}\"Help me connect to VeloDB Cloud\"${RESET}\n\n"
    printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
}

show_uninstall_summary() {
    echo; printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
    printf "  ${CHECK} ${BOLD}Uninstall complete.${RESET}\n\n"
    printf "  ${DIM}To reinstall: ./install.sh${RESET}\n"
    printf "  ${DIM}To also remove velocli: npm uninstall -g @velodb/velocli${RESET}\n\n"
    printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
}

show_update_summary() {
    echo; printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
    printf "  ${CHECK} ${BOLD}Update complete!${RESET} ${DIM}(v%s)${RESET}\n\n" "$VERSION"
    printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
}

show_prereqs() {
    echo
    printf "  ${DIAMOND} ${BOLD}Prerequisites${RESET}\n\n"
    printf "  ${WHITE}Required:${RESET}\n"
    printf "    ${DIM}•${RESET} An AI coding assistant (Claude Code, Cursor, Windsurf, etc.)\n"
    printf "    ${DIM}•${RESET} VeloDB Cloud account or self-hosted Apache Doris cluster\n\n"
    printf "  ${WHITE}Optional (for CLI diagnostics):${RESET}\n"
    printf "    ${DIM}•${RESET} Node.js ≥ 16 for velocli: ${WHITE}npm install -g @velodb/velocli${RESET}\n"
    printf "    ${DIM}•${RESET} VeloDB Cloud API key from: ${WHITE}https://www.velodb.cloud/organization/api-keys${RESET}\n"
    printf "    ${DIM}•${RESET} MySQL password (set during warehouse creation)\n\n"
}

show_help() {
    show_banner
    printf "  ${BOLD}Usage:${RESET}  ./install.sh [action] [options]\n\n"
    printf "  ${BOLD}Actions:${RESET}\n\n"
    printf "    ${WHITE}install${RESET}   ${DIM}(default)${RESET}  Install skills\n"
    printf "    ${WHITE}update${RESET}              Update skills to latest version\n"
    printf "    ${WHITE}uninstall${RESET}           Remove skills\n\n"
    printf "  ${BOLD}Scope:${RESET}\n\n"
    printf "    ${DIM}(default)${RESET}           Project-level ${DIM}(./.claude/skills/ in current directory)${RESET}\n"
    printf "    ${WHITE}-g, --global${RESET}        Global-level ${DIM}(~/.claude/skills/ in home directory)${RESET}\n\n"
    printf "  ${BOLD}Target:${RESET}\n\n"
    printf "    ${DIM}(default)${RESET}           Auto-detect installed agents\n"
    printf "    ${WHITE}--agent <name>${RESET}      Specific agent: claude, cursor, windsurf, antigravity,\n"
    printf "                       codex, gemini, kiro, copilot\n"
    printf "    ${WHITE}--path <dir>${RESET}        Custom directory\n\n"
    printf "  ${BOLD}Other:${RESET}\n\n"
    printf "    ${WHITE}--velocli${RESET}           Install velocli CLI only\n"
    printf "    ${WHITE}--prereqs${RESET}           Show prerequisites\n"
    printf "    ${WHITE}--version${RESET}           Show version\n"
    printf "    ${WHITE}-h, --help${RESET}          Show this help\n\n"
    printf "  ${BOLD}Examples:${RESET}\n\n"
    printf "    ./install.sh                        ${DIM}Install to project, auto-detect agents${RESET}\n"
    printf "    ./install.sh --agent claude          ${DIM}Install to ./.claude/skills/${RESET}\n"
    printf "    ./install.sh -g                      ${DIM}Install to ~/.claude/skills/ (global)${RESET}\n"
    printf "    ./install.sh -g --agent cursor       ${DIM}Install to ~/.cursor/skills/ (global)${RESET}\n"
    printf "    ./install.sh update                  ${DIM}Update project-level skills${RESET}\n"
    printf "    ./install.sh update -g               ${DIM}Update global skills${RESET}\n"
    printf "    ./install.sh uninstall               ${DIM}Remove project-level skills${RESET}\n"
    printf "    ./install.sh uninstall -g             ${DIM}Remove global skills${RESET}\n"
    printf "    ./install.sh --path ./my-skills      ${DIM}Install to custom directory${RESET}\n\n"
}

# ─── Parse args ─────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        install)    ACTION="install"; shift ;;
        update)     ACTION="update"; shift ;;
        uninstall)  ACTION="uninstall"; shift ;;
        -g|--global) SCOPE="global"; shift ;;
        --agent)    TARGET_AGENT="$2"; shift 2 ;;
        --path)     CUSTOM_PATH="$2"; shift 2 ;;
        --velocli)  show_banner; install_velocli; echo; exit 0 ;;
        --prereqs)  show_banner; show_prereqs; exit 0 ;;
        --version)  echo "velodb-agent-skills $VERSION"; exit 0 ;;
        -h|--help)  show_help; exit 0 ;;
        *)          printf "  ${CROSS} Unknown: $1. Use --help\n"; exit 1 ;;
    esac
done

# ─── Execute ────────────────────────────────────────────────────────────────

show_banner

scope_label="project ($(pwd))"
[[ "$SCOPE" == "global" ]] && scope_label="global (~)"
printf "  ${DIM}Scope: %s${RESET}\n" "$scope_label"

case "$ACTION" in
    install)
        printf "  ${DIM}Action: install${RESET}\n\n"
        if [[ -n "$CUSTOM_PATH" ]]; then
            install_all_skills_to_dir "$CUSTOM_PATH"
        elif [[ -n "$TARGET_AGENT" ]]; then
            run_on_agent "$TARGET_AGENT" install_all_skills_to_dir
        else
            run_on_all_detected install_all_skills_to_dir
        fi
        maybe_ask_velocli
        show_install_summary
        ;;
    update)
        printf "  ${DIM}Action: update${RESET}\n\n"
        if [[ -n "$CUSTOM_PATH" ]]; then
            update_skills_in_dir "$CUSTOM_PATH"
        elif [[ -n "$TARGET_AGENT" ]]; then
            run_on_agent "$TARGET_AGENT" update_skills_in_dir
        else
            run_on_all_detected update_skills_in_dir
        fi
        show_update_summary
        ;;
    uninstall)
        printf "  ${DIM}Action: uninstall${RESET}\n\n"
        if [[ -n "$CUSTOM_PATH" ]]; then
            uninstall_skills_from_dir "$CUSTOM_PATH"
        elif [[ -n "$TARGET_AGENT" ]]; then
            run_on_agent "$TARGET_AGENT" uninstall_skills_from_dir
        else
            run_on_all_detected uninstall_skills_from_dir
        fi
        show_uninstall_summary
        ;;
esac
