#!/usr/bin/env bash
# VeloDB Best Practices Skill Installer v2.0
# Direct copy to agent-specific skill directories
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
CHECK="${GREEN}✓${RESET}"; CROSS="${RED}✗${RESET}"; ARROW="${CYAN}▸${RESET}"; DIAMOND="${MAGENTA}◆${RESET}"
SKILL_NAME="velodb-best-practices"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    │       Best Practices Skill v2.0         │
    ╰─────────────────────────────────────────╯
B
    printf "${RESET}\n  ${DIM}37 rules · 7 use cases · 4 sizing guides${RESET}\n\n"
}

progress_bar() {
    local c=$1 t=$2 pct=$(($1*100/$2)) f=$(($1*30/$2)) e=$((30-$1*30/$2)) b=""
    for((i=0;i<f;i++));do b+="█";done; for((i=0;i<e;i++));do b+="░";done
    printf "\r  ${DIM}[${RESET}${GREEN}%s${RESET}${DIM}]${RESET} ${WHITE}%3d%%${RESET}" "$b" "$pct"
}

install_to_dir() {
    local d="$1/$SKILL_NAME"; mkdir -p "$d/references"
    local fs=("$SCRIPT_DIR/SKILL.md"); [ -f "$SCRIPT_DIR/AGENTS.md" ] && fs+=("$SCRIPT_DIR/AGENTS.md")
    local rs=("$SCRIPT_DIR/references/"*.md); local t=$((${#fs[@]}+${#rs[@]})) c=0
    for f in "${fs[@]}";do [ -f "$f" ]&&cp "$f" "$d/"; c=$((c+1)); progress_bar $c $t; sleep 0.02; done
    for f in "${rs[@]}";do [ -f "$f" ]&&cp "$f" "$d/references/"; c=$((c+1)); progress_bar $c $t; sleep 0.02; done
    echo; printf "  ${CHECK} Installed to ${CYAN}%s${RESET}\n" "$d"
}

show_summary() {
    echo; printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
    printf "  ${CHECK} ${BOLD}Installation complete!${RESET}\n\n"
    printf "  ${DIAMOND} ${WHITE}What's included:${RESET}\n"
    printf "     ${DIM}├─${RESET} 37 table design rules (CRITICAL → MEDIUM)\n"
    printf "     ${DIM}├─${RESET} 7 use case templates with complete SQL\n"
    printf "     ${DIM}├─${RESET} Decision flowchart for workload routing\n"
    printf "     ${DIM}├─${RESET} Problem-first troubleshooting index\n"
    printf "     ${DIM}└─${RESET} Cluster sizing guides\n\n"
    printf "  ${DIAMOND} ${WHITE}Try it:${RESET}\n"
    printf "     ${DIM}\"Design a table for real-time fleet tracking analytics\"${RESET}\n"
    printf "     ${DIM}\"Review this CREATE TABLE for best practices\"${RESET}\n"
    printf "     ${DIM}\"My queries on the orders table are slow\"${RESET}\n\n"
    printf "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
}

# Agent install paths (project-scope uses CWD, global uses HOME)
declare -A AGENT_DIRS=(
    [claude]="$HOME/.claude/skills"
    [antigravity]="$HOME/.gemini/antigravity/skills"
    [cursor]="$HOME/.cursor/skills"
    [windsurf]="$HOME/.codeium/windsurf/skills"
    [codex]="$HOME/.codex/skills"
    [gemini]="$HOME/.gemini-cli/skills"
    [copilot]="$HOME/.github/copilot/skills"
)

detect_agents() {
    local found=()
    for name in "${!AGENT_DIRS[@]}"; do
        local dir="${AGENT_DIRS[$name]}"
        local parent="$(dirname "$dir")"
        [ -d "$parent" ] && found+=("$name")
    done
    echo "${found[@]}"
}

install_all_detected() {
    local agents=($(detect_agents))
    if [ ${#agents[@]} -eq 0 ]; then
        printf "  ${CROSS} No agents detected. Use ${WHITE}--path DIR${RESET} to install manually.\n"
        return 1
    fi
    printf "  ${DIAMOND} Detected ${WHITE}${#agents[@]}${RESET} agents: ${CYAN}%s${RESET}\n\n" "${agents[*]}"
    for name in "${agents[@]}"; do
        install_to_dir "${AGENT_DIRS[$name]}"
    done
}

case "${1:-}" in
    --claude)       show_banner; install_to_dir "${AGENT_DIRS[claude]}"; show_summary ;;
    --antigravity)  show_banner; install_to_dir "${AGENT_DIRS[antigravity]}"; show_summary ;;
    --cursor)       show_banner; install_to_dir "${AGENT_DIRS[cursor]}"; show_summary ;;
    --windsurf)     show_banner; install_to_dir "${AGENT_DIRS[windsurf]}"; show_summary ;;
    --codex)        show_banner; install_to_dir "${AGENT_DIRS[codex]}"; show_summary ;;
    --all)          show_banner; install_all_detected; show_summary ;;
    --path)         show_banner
                    [ -z "${2:-}" ] && { printf "  ${CROSS} --path needs a directory\n"; exit 1; }
                    install_to_dir "$2"; show_summary ;;
    --help|-h)      show_banner
        printf "  ${BOLD}Usage:${RESET}\n\n"
        printf "    ./install.sh               ${DIM}Interactive menu${RESET}\n"
        printf "    ./install.sh --all          ${DIM}Auto-detect & install to all agents${RESET}\n"
        printf "    ./install.sh --claude       ${DIM}~/.claude/skills/${RESET}\n"
        printf "    ./install.sh --antigravity  ${DIM}~/.gemini/antigravity/skills/${RESET}\n"
        printf "    ./install.sh --cursor       ${DIM}~/.cursor/skills/${RESET}\n"
        printf "    ./install.sh --windsurf     ${DIM}~/.codeium/windsurf/skills/${RESET}\n"
        printf "    ./install.sh --codex        ${DIM}~/.codex/skills/${RESET}\n"
        printf "    ./install.sh --path DIR     ${DIM}Custom directory${RESET}\n\n"
        printf "  ${BOLD}For remote install:${RESET}\n"
        printf "    ${GREEN}npx skills add <github-repo>${RESET}  ${DIM}(run from project root, not skill dir)${RESET}\n\n" ;;
    "") show_banner
        printf "  ${DIAMOND} ${BOLD}Choose target:${RESET}\n\n"
        printf "    ${WHITE}1)${RESET} ${BOLD}Auto-detect${RESET}   ${DIM}Install to all detected agents${RESET}\n"
        printf "    ${WHITE}2)${RESET} Claude Code\n"
        printf "    ${WHITE}3)${RESET} Antigravity\n"
        printf "    ${WHITE}4)${RESET} Cursor\n"
        printf "    ${WHITE}5)${RESET} Windsurf\n"
        printf "    ${WHITE}6)${RESET} Custom path\n\n"
        printf "  ${ARROW} Choice ${DIM}[1-6]:${RESET} "; read -r tc
        case "${tc:-1}" in
            1) install_all_detected ;;
            2) install_to_dir "${AGENT_DIRS[claude]}" ;;
            3) install_to_dir "${AGENT_DIRS[antigravity]}" ;;
            4) install_to_dir "${AGENT_DIRS[cursor]}" ;;
            5) install_to_dir "${AGENT_DIRS[windsurf]}" ;;
            6) printf "  ${ARROW} Path: "; read -r p; install_to_dir "$p" ;;
        esac; show_summary ;;
    *) printf "  ${CROSS} Unknown: $1. Use --help\n"; exit 1 ;;
esac
