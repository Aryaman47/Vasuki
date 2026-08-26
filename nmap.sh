#!/usr/bin/env bash
# nmap.sh - Nmap service enumeration module for Vasuki / vash

_extract_nmap_target() {
    local raw_target="$1"
    local host="${raw_target#*://}"
    host="${host%%/*}"
    host="${host%%:*}"
    echo "${host}"
}

show_nmap_help() {
    local nmap_target="${1:-<target>}"
    echo -e "\n${COLOR_BOLD}=== Nmap Module Scan Profiles Reference ===${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ Basic Scans ]${COLOR_RESET}"
    echo -e "  1. Fast Scan"
    echo -e "     ${COLOR_CYAN}nmap -F ${nmap_target}${COLOR_RESET}"
    echo -e "  2. Ping Discovery (No Port Scan)"
    echo -e "     ${COLOR_CYAN}nmap -sn ${nmap_target}${COLOR_RESET}"
    echo -e "  3. Default Top 1000 Ports"
    echo -e "     ${COLOR_CYAN}nmap ${nmap_target}${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ Moderate Scans ]${COLOR_RESET}"
    echo -e "  4. Service Version Detection"
    echo -e "     ${COLOR_CYAN}nmap -sV ${nmap_target}${COLOR_RESET}"
    echo -e "  5. Default Scripts & Version Detection"
    echo -e "     ${COLOR_CYAN}nmap -sC -sV ${nmap_target}${COLOR_RESET}"
    echo -e "  6. OS & Version Detection"
    echo -e "     ${COLOR_CYAN}nmap -O -sV ${nmap_target}${COLOR_RESET}"
    echo -e "  7. SYN Stealth Scan + Service Detection"
    echo -e "     ${COLOR_CYAN}nmap -sS -sV ${nmap_target}${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ Advanced Scans ]${COLOR_RESET}"
    echo -e "  8. Aggressive Scan (OS, Version, Scripts, Traceroute)"
    echo -e "     ${COLOR_CYAN}nmap -A ${nmap_target}${COLOR_RESET}"
    echo -e "  9. Full All Ports Scan (1-65535)"
    echo -e "     ${COLOR_CYAN}nmap -p- -sC -sV ${nmap_target}${COLOR_RESET}"
    echo -e " 10. UDP Top 100 Ports Scan"
    echo -e "     ${COLOR_CYAN}nmap -sU --top-ports 100 ${nmap_target}${COLOR_RESET}"
    echo -e " 11. Vulnerability Assessment Scan"
    echo -e "     ${COLOR_CYAN}nmap --script vuln ${nmap_target}${COLOR_RESET}\n"

    echo -e "${COLOR_BOLD}Usage:${COLOR_RESET} nmap [profile_num|scan_type]"
    echo -e "${COLOR_BOLD}Examples:${COLOR_RESET} 'nmap 1' (Fast Scan) | 'nmap 8' (Aggressive Scan) | 'nmap' (Interactive Menu)\n"
}

run_nmap() {
    local target="$1"
    local arg="${2:-}"
    local nmap_target
    local choice=""
    local flags=""

    # If help requested, display reference without requiring a target
    if [[ "${arg,,}" == "?" || "${arg,,}" == "help" || "${arg,,}" == "-h" || "${arg,,}" == "--help" ]]; then
        show_nmap_help "${target:+$(extract_host "${target}")}"
        return 0
    fi

    if [[ -z "${target}" ]]; then
        print_error "No active target set. Use 'target <URL|IP>' to set a target first, or 'nmap ?' for help."
        return 0
    fi

    nmap_target="$(_extract_nmap_target "${target}")"

    # If direct argument profile was passed (e.g. nmap 1 or nmap fast)
    if [[ -n "${arg}" ]]; then
        case "${arg,,}" in
            1|fast) flags="-F" ;;
            2|ping) flags="-sn" ;;
            3|top|default) flags="" ;;
            4|sv|version) flags="-sV" ;;
            5|sc|scripts) flags="-sC -sV" ;;
            6|os) flags="-O -sV" ;;
            7|syn|stealth) flags="-sS -sV" ;;
            8|aggressive|a) flags="-A" ;;
            9|all|full) flags="-p- -sC -sV" ;;
            10|udp) flags="-sU --top-ports 100" ;;
            11|vuln) flags="--script vuln" ;;
            *)
                flags="${arg}"
                ;;
        esac

        local -a flags_arr=()
        if [[ -n "${flags}" ]]; then
            read -r -a flags_arr <<< "${flags}"
        fi
        print_info "Executing: nmap ${flags} ${nmap_target}"
        echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
        if ! nmap "${flags_arr[@]}" "${nmap_target}"; then
            print_error "Nmap scan execution failed or was interrupted."
        else
            print_success "Nmap scan completed successfully."
        fi
        return 0
    fi

    while true; do
        menu_header "${target}"
        show_nmap_help "${nmap_target}"

        echo -e "  0. Back to vash Shell (or type 'back')\n"
        echo -en "${COLOR_CYAN}Select Nmap Scan Option [1-11 / type 'back']: ${COLOR_RESET}"

        read -r choice
        choice="$(echo "${choice}" | awk '{$1=$1;print}')"
        local lower_choice="${choice,,}"

        case "${lower_choice}" in
            1) flags="-F" ;;
            2) flags="-sn" ;;
            3) flags="" ;;
            4) flags="-sV" ;;
            5) flags="-sC -sV" ;;
            6) flags="-O -sV" ;;
            7) flags="-sS -sV" ;;
            8) flags="-A" ;;
            9) flags="-p- -sC -sV" ;;
            10) flags="-sU --top-ports 100" ;;
            11) flags="--script vuln" ;;
            0|12|b|back)
                print_info "Navigating back to vash shell..."
                break
                ;;
            *)
                print_error "Invalid selection. Please choose 1-11, or type 'back' to return."
                pause
                continue
                ;;
        esac

        local -a flags_arr=()
        if [[ -n "${flags}" ]]; then
            read -r -a flags_arr <<< "${flags}"
        fi
        print_info "Executing: nmap ${flags} ${nmap_target}"
        echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"

        if ! nmap "${flags_arr[@]}" "${nmap_target}"; then
            print_error "Nmap scan execution failed or was interrupted."
        else
            print_success "Nmap scan completed successfully."
        fi

        pause
    done
}
