#!/usr/bin/env bash
# seclists.sh - Locates and selects SecLists Web-Content wordlists

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Source config and common helpers if available
if [[ -f "${SCRIPT_DIR}/config.sh" ]]; then
    # shellcheck source=config.sh
    source "${SCRIPT_DIR}/config.sh"
fi
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
    # shellcheck source=common.sh
    source "${SCRIPT_DIR}/common.sh"
else
    COLOR_CYAN="\033[0;36m"
    COLOR_GREEN="\033[0;32m"
    COLOR_RED="\033[0;31m"
    COLOR_BOLD="\033[1m"
    COLOR_RESET="\033[0m"
    print_info() { echo -e "${COLOR_CYAN}[*] $1${COLOR_RESET}"; }
    print_success() { echo -e "${COLOR_GREEN}[+] $1${COLOR_RESET}"; }
    print_error() { echo -e "${COLOR_RED}[-] $1${COLOR_RESET}" >&2; }
fi

SECLISTS_BASE_DIRS=(
    "/usr/share/wordlists/seclists/Discovery/Web-Content"
    "/usr/share/wordlists/SecLists/Discovery/Web-Content"
    "/usr/share/seclists/Discovery/Web-Content"
    "/opt/seclists/Discovery/Web-Content"
)

locate_seclists_dir() {
    local dir
    for dir in "${SECLISTS_BASE_DIRS[@]}"; do
        if [[ -d "${dir}" ]]; then
            echo "${dir}"
            return 0
        fi
    done
    return 1
}

select_seclist_wordlist() {
    local target_dir
    target_dir="$(locate_seclists_dir || true)"

    if [[ -z "${target_dir}" ]]; then
        print_error "SecLists Web-Content directory not found under standard paths:"
        for dir in "${SECLISTS_BASE_DIRS[@]}"; do
            echo "  - ${dir}"
        done
        print_info "Please install SecLists (e.g. 'sudo apt install seclists') or check your installation path."
        return 1
    fi

    print_info "Found SecLists Web-Content directory: ${target_dir}"
    print_info "Scanning for wordlists..."

    local wordlists=()
    while IFS= read -r -d '' file; do
        wordlists+=("${file}")
    done < <(find "${target_dir}" -type f \( -name "*.txt" -o -name "*.lst" \) -print0 | sort -z)

    if [[ ${#wordlists[@]} -eq 0 ]]; then
        print_error "No wordlist files found in ${target_dir}"
        return 1
    fi

    echo -e "\n${COLOR_BOLD}=== Available SecLists Web-Content Wordlists (${#wordlists[@]} found) ===${COLOR_RESET}"
    local i
    for i in "${!wordlists[@]}"; do
        local rel_path="${wordlists[$i]#${target_dir}/}"
        printf "%3d) %s\n" "$((i + 1))" "${rel_path}"
    done
    echo "  0) Back to Wordlist Selection (or type 'back')"

    local choice=""
    while true; do
        echo -en "\n${COLOR_CYAN}Select wordlist number [1-${#wordlists[@]} / type 'back']: ${COLOR_RESET}"
        read -r choice
        choice="$(echo "${choice}" | awk '{$1=$1;print}')"
        local lower_choice="${choice,,}"

        if [[ "${lower_choice}" == "0" || "${lower_choice}" == "b" || "${lower_choice}" == "back" ]]; then
            print_info "Navigating back to Wordlist Selection..."
            return 1
        fi

        if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#wordlists[@]} )); then
            local selected_file="${wordlists[$((choice - 1))]}"
            print_success "Selected wordlist: ${selected_file}"
            SELECTED_WORDLIST="${selected_file}"
            return 0
        else
            print_error "Invalid selection. Enter a number between 1 and ${#wordlists[@]}, or type 'back'."
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    select_seclist_wordlist
fi