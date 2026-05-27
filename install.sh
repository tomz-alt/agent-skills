#!/usr/bin/env bash
# VeloDB Agent Skills Installer v3.0
# Installs all skills into agent-specific skill directories
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; YELLOW='\033[0;33m'
CHECK="${GREEN}✓${RESET}"; CROSS="${RED}✗${RESET}"; ARROW="${CYAN}▸${RESET}"; DIAMOND="${MAGENTA}◆${RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
SKILLS=("velodb-architecture-advisor" "velodb-best-practices" "velocli-cloud")

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
    │         Agent Skills v3.0               │
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

install_skill_to_dir() {
    local skill_name="$1" target_base="$2"
    local src="$SKILLS_DIR/$skill_name"
    local dest="$target_base/$skill_name"

    if [[ ! -d "$src" ]]; then
        printf "  ${CROSS} ${skill_name} source not found at ${src}\n"
        return 1
    fi

    mkdir -p "$dest"
    [[ -d "$src/references" ]] && mkdir -p "$dest/references"

    # Count files
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
}

# Agent install paths
declare -A AGENT_DIRS=(
    [claude]="$HOME/.claude/skills"
    [antigravity]="$HOME/.gemini/antigravity/skills"
    [cursor]="$HOME/.cursor/skills"
    [windsurf]="$HOME/.codeium/windsurf/skills"
    [codex]="$HOME/.codex/skills"
    [gemini]="$HOME/.gemini-cli/skills"
    [copilot]="$HOME/.github/copilot/skills"
    [kiro]="$HOME/.kiro/skills"
)

detect_agents() {
    local found=()
    for name in "${!AGENT_DIRS[@]}"; do
        local dir="${AGENT_DIRS[$name]}"
        local parent="$(dirname "$dir")"
        [[ -d "$parent" ]] && found+=("$name")
    done
    echo "${found[@]}"
}

install_all_detected() {
    local agents=($(detect_agents))
    if [[ ${#agents[@]} -eq 0 ]]; then
        printf "  ${CROSS} No agents detected. Use ${WHITE}--path DIR${RESET} to install manually.\n"
        return 1
    fi
    printf "  ${DIAMOND} Detected ${WHITE}${#agents[@]}${RESET} agent(s): ${CYAN}%s${RESET}\n\n" "${agents[*]}"
    for name in "${agents[@]}"; do
        printf "\n  ${BOLD}[%s]${RESET}\n" "$name"
        install_all_skills_to_dir "${AGENT_DIRS[$name]}"
    done
}

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

show_summary() {
    echo; printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
    printf "  ${CHECK} ${BOLD}Installation complete!${RESET}\n\n"
    printf "  ${DIAMOND} ${WHITE}What's included:${RESET}\n"
    printf "     ${DIM}├─${RESET} ${BOLD}velodb-architecture-advisor${RESET}\n"
    printf "     ${DIM}│  ${RESET} ${DIM}8 decision frameworks · 10 industry examples${RESET}\n"
    printf "     ${DIM}│  ${RESET} ${DIM}IoT, retail, securities, logistics, gaming, adtech...${RESET}\n"
    printf "     ${DIM}├─${RESET} ${BOLD}velodb-best-practices${RESET}\n"
    printf "     ${DIM}│  ${RESET} ${DIM}37 rules · 7 use case templates · 5 DDL templates${RESET}\n"
    printf "     ${DIM}│  ${RESET} ${DIM}CLI-based query diagnosis · profile/tablet evidence${RESET}\n"
    printf "     ${DIM}└─${RESET} ${BOLD}velocli-cloud${RESET}\n"
    printf "        ${DIM}Cloud onboarding · cluster lifecycle · billing · audit${RESET}\n"
    printf "        ${DIM}Networking · troubleshooting · stateless/CI mode${RESET}\n\n"

    # Check velocli
    if command -v velocli >/dev/null 2>&1; then
        printf "  ${CHECK} velocli: ${CYAN}$(velocli --version)${RESET}\n"
    elif command -v npx >/dev/null 2>&1 && npx velocli --version >/dev/null 2>&1; then
        printf "  ${CHECK} velocli (via npx): ${CYAN}$(npx velocli --version 2>/dev/null)${RESET}\n"
    else
        printf "  ${DIM}○${RESET} velocli: not installed ${DIM}(optional — skills work without it)${RESET}\n"
        printf "    Install: ${WHITE}npm install -g @velodb/velocli${RESET}\n"
    fi

    echo
    printf "  ${DIAMOND} ${WHITE}Try it:${RESET}\n"
    printf "     ${DIM}\"Design a table for real-time fleet tracking analytics\"${RESET}\n"
    printf "     ${DIM}\"Review this CREATE TABLE for best practices\"${RESET}\n"
    printf "     ${DIM}\"My queries on the orders table are slow\"${RESET}\n"
    printf "     ${DIM}\"Help me connect to VeloDB Cloud\"${RESET}\n"
    printf "     ${DIM}\"Pause the analytics cluster\"${RESET}\n\n"
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
    printf "  ${WHITE}Connection info (from Cloud console → Connection Methods):${RESET}\n"
    printf "    ${DIM}•${RESET} MySQL CLI:    ${DIM}mysql -h <host> -P 9030 -u admin -p<password>${RESET}\n"
    printf "    ${DIM}•${RESET} JDBC:         ${DIM}jdbc:mysql://<host>:9030/<db>?user=admin${RESET}\n"
    printf "    ${DIM}•${RESET} StreamLoad:   ${DIM}http://<host>:8080${RESET}\n"
    printf "    ${DIM}•${RESET} HTTP port:    ${DIM}8080 (VeloDB Cloud) or 8030 (self-hosted Doris)${RESET}\n\n"
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

case "${1:-}" in
    --claude)       show_banner; install_all_skills_to_dir "${AGENT_DIRS[claude]}"; maybe_ask_velocli; show_summary ;;
    --antigravity)  show_banner; install_all_skills_to_dir "${AGENT_DIRS[antigravity]}"; maybe_ask_velocli; show_summary ;;
    --cursor)       show_banner; install_all_skills_to_dir "${AGENT_DIRS[cursor]}"; maybe_ask_velocli; show_summary ;;
    --windsurf)     show_banner; install_all_skills_to_dir "${AGENT_DIRS[windsurf]}"; maybe_ask_velocli; show_summary ;;
    --codex)        show_banner; install_all_skills_to_dir "${AGENT_DIRS[codex]}"; maybe_ask_velocli; show_summary ;;
    --gemini)       show_banner; install_all_skills_to_dir "${AGENT_DIRS[gemini]}"; maybe_ask_velocli; show_summary ;;
    --kiro)         show_banner; install_all_skills_to_dir "${AGENT_DIRS[kiro]}"; maybe_ask_velocli; show_summary ;;
    --all)          show_banner; install_all_detected; maybe_ask_velocli; show_summary ;;
    --velocli)      show_banner; install_velocli; echo ;;
    --prereqs)      show_banner; show_prereqs ;;
    --path)         show_banner
                    [[ -z "${2:-}" ]] && { printf "  ${CROSS} --path needs a directory\n"; exit 1; }
                    install_all_skills_to_dir "$2"; maybe_ask_velocli; show_summary ;;
    --help|-h)      show_banner
        printf "  ${BOLD}Usage:${RESET}\n\n"
        printf "    ./install.sh               ${DIM}Interactive menu${RESET}\n"
        printf "    ./install.sh --all          ${DIM}Auto-detect & install to all agents${RESET}\n"
        printf "    ./install.sh --claude       ${DIM}~/.claude/skills/${RESET}\n"
        printf "    ./install.sh --antigravity  ${DIM}~/.gemini/antigravity/skills/${RESET}\n"
        printf "    ./install.sh --cursor       ${DIM}~/.cursor/skills/${RESET}\n"
        printf "    ./install.sh --windsurf     ${DIM}~/.codeium/windsurf/skills/${RESET}\n"
        printf "    ./install.sh --codex        ${DIM}~/.codex/skills/${RESET}\n"
        printf "    ./install.sh --gemini       ${DIM}~/.gemini-cli/skills/${RESET}\n"
        printf "    ./install.sh --kiro         ${DIM}~/.kiro/skills/${RESET}\n"
        printf "    ./install.sh --path DIR     ${DIM}Custom directory${RESET}\n"
        printf "    ./install.sh --velocli      ${DIM}Install velocli CLI only${RESET}\n"
        printf "    ./install.sh --prereqs      ${DIM}Show prerequisites${RESET}\n\n"
        printf "  ${BOLD}For remote install:${RESET}\n"
        printf "    ${GREEN}npx skills add <github-repo>${RESET}  ${DIM}(run from project root)${RESET}\n\n" ;;
    "") show_banner
        printf "  ${DIAMOND} ${BOLD}Choose target:${RESET}\n\n"
        printf "    ${WHITE}1)${RESET} ${BOLD}Auto-detect${RESET}    ${DIM}Install to all detected agents${RESET}\n"
        printf "    ${WHITE}2)${RESET} Claude Code\n"
        printf "    ${WHITE}3)${RESET} Antigravity\n"
        printf "    ${WHITE}4)${RESET} Cursor\n"
        printf "    ${WHITE}5)${RESET} Windsurf\n"
        printf "    ${WHITE}6)${RESET} Custom path\n"
        printf "    ${WHITE}7)${RESET} ${DIM}Show prerequisites${RESET}\n\n"
        printf "  ${ARROW} Choice ${DIM}[1-7]:${RESET} "; read -r tc
        case "${tc:-1}" in
            1) install_all_detected ;;
            2) install_all_skills_to_dir "${AGENT_DIRS[claude]}" ;;
            3) install_all_skills_to_dir "${AGENT_DIRS[antigravity]}" ;;
            4) install_all_skills_to_dir "${AGENT_DIRS[cursor]}" ;;
            5) install_all_skills_to_dir "${AGENT_DIRS[windsurf]}" ;;
            6) printf "  ${ARROW} Path: "; read -r p; install_all_skills_to_dir "$p" ;;
            7) show_prereqs; exit 0 ;;
        esac

        maybe_ask_velocli
        show_summary ;;
    *) printf "  ${CROSS} Unknown: $1. Use --help\n"; exit 1 ;;
esac
