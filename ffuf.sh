#!/usr/bin/env bash
# ffuf.sh - FFUF directory/file fuzzing module for Vasuki / vash

_prepare_ffuf_url() {
    local raw_url="$1"
    local url="${raw_url%/}"

    if [[ "${url}" != *"FUZZ"* ]]; then
        url="${url}/FUZZ"
    fi

    echo "${url}"
}

show_ffuf_help() {
    local url="${1:-<target_url>/FUZZ}"
    echo -e "\n${COLOR_BOLD}=== FFUF Fuzzing Module Reference ===${COLOR_RESET}\n"
    echo -e "  - Fuzzes web directories and files by replacing the 'FUZZ' keyword."
    echo -e "  - Automatically appends '/FUZZ' if no FUZZ keyword is present in target."
    echo -e "  - Automatically logs user-provided wordlist paths to history.\n"
    echo -e "${COLOR_BOLD}Target URL Format:${COLOR_RESET} ${COLOR_CYAN}ffuf -u ${url} -w <wordlist>${COLOR_RESET}\n"
    echo -e "${COLOR_BOLD}Usage:${COLOR_RESET} ffuf [wordlist_path]"
    echo -e "${COLOR_BOLD}Examples:${COLOR_RESET}"
    echo -e "  - ${COLOR_CYAN}ffuf${COLOR_RESET}                           : Open interactive wordlist selector"
    echo -e "  - ${COLOR_CYAN}ffuf /usr/share/wordlists/...${COLOR_RESET}  : Run fuzzing using specific wordlist file\n"
}

run_ffuf() {
    local target="$1"
    local custom_wordlist="${2:-}"
    local ffuf_url

    # If help requested, display reference without requiring a target
    if [[ "${custom_wordlist,,}" == "?" || "${custom_wordlist,,}" == "help" || "${custom_wordlist,,}" == "-h" || "${custom_wordlist,,}" == "--help" ]]; then
        show_ffuf_help "${target:+$(_prepare_ffuf_url "${target}")}"
        return 0
    fi

    if [[ -z "${target}" ]]; then
        print_error "No active target set. Use 'target <URL|IP>' to set a target first, or 'ffuf ?' for help."
        return 0
    fi

    ffuf_url="$(_prepare_ffuf_url "${target}")"

    if [[ -n "${custom_wordlist}" ]]; then
        if [[ "${custom_wordlist}" == "~"* ]]; then
            custom_wordlist="${HOME}${custom_wordlist#\~}"
        fi
        if [[ -f "${custom_wordlist}" ]]; then
            SELECTED_WORDLIST="${custom_wordlist}"
            save_wordlist_path "${custom_wordlist}"
        else
            print_error "Wordlist file not found: '${custom_wordlist}'"
            return 0
        fi
    else
        if ! select_wordlist; then
            return 0
        fi
    fi

    if [[ -z "${SELECTED_WORDLIST:-}" ]]; then
        return 0
    fi

    print_info "Starting FFUF scan..."
    print_info "Target URL: ${ffuf_url}"
    print_info "Wordlist:   ${SELECTED_WORDLIST}"
    print_info "Command:    ffuf -u ${ffuf_url} -w ${SELECTED_WORDLIST}"
    echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"

    if ! ffuf -u "${ffuf_url}" -w "${SELECTED_WORDLIST}"; then
        print_error "FFUF execution failed or interrupted."
    else
        print_success "FFUF scan completed successfully."
    fi

    pause
}