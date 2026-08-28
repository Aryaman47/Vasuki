#!/usr/bin/env bash
# hashcat.sh - Hashcat offline password recovery module for Vasuki / vash

_get_hashcat_mode() {
    local profile="$1"
    case "${profile,,}" in
        1|md5) echo "0" ;;
        2|sha1) echo "100" ;;
        3|sha256) echo "1400" ;;
        4|sha512) echo "1700" ;;
        5|ntlm|sam|activedirectory) echo "1000" ;;
        6|linux|sha512crypt|unix) echo "1800" ;;
        7|bcrypt|mac|openbsd) echo "3200" ;;
        8|wifi|wpa|wpa2|pmkid) echo "22000" ;;
        9|kerberos|kerberoast|krb5tgs) echo "13100" ;;
        10|zip|pkzip) echo "13600" ;;
        11|rar|rar5) echo "13000" ;;
        12|pdf) echo "10500" ;;
        *)
            if [[ "${profile}" =~ ^[0-9]+$ ]]; then
                echo "${profile}"
            else
                echo "0"
            fi
            ;;
    esac
}

_get_hashcat_title() {
    local profile="$1"
    case "${profile,,}" in
        1|md5) echo "MD5 (Mode 0)" ;;
        2|sha1) echo "SHA1 (Mode 100)" ;;
        3|sha256) echo "SHA256 (Mode 1400)" ;;
        4|sha512) echo "SHA512 (Mode 1700)" ;;
        5|ntlm|sam|activedirectory) echo "NTLM - Windows SAM/AD (Mode 1000)" ;;
        6|linux|sha512crypt|unix) echo "Linux SHA512-Crypt \$6\$ (Mode 1800)" ;;
        7|bcrypt|mac|openbsd) echo "bcrypt \$2a\$/\$2b\$ (Mode 3200)" ;;
        8|wifi|wpa|wpa2|pmkid) echo "WPA/WPA2 PMKID / EAPOL (Mode 22000)" ;;
        9|kerberos|kerberoast|krb5tgs) echo "Kerberos 5 TGS-REP krb5tgs (Mode 13100)" ;;
        10|zip|pkzip) echo "ZIP / PKZIP (Mode 13600)" ;;
        11|rar|rar5) echo "RAR5 (Mode 13000)" ;;
        12|pdf) echo "PDF 1.4 - 1.6 (Mode 10500)" ;;
        *) echo "Custom Mode (${profile})" ;;
    esac
}

show_hashcat_help() {
    local target_file="${1:-<hash_file>}"
    echo -e "\n${COLOR_BOLD}=== Hashcat Module Attack Profiles Reference ===${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ Web & Standard Hashes ]${COLOR_RESET}"
    echo -e "  1. MD5"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 0 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e "  2. SHA1"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 100 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e "  3. SHA256"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 1400 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e "  4. SHA512"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 1700 ${target_file} <wordlist>${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ OS & System Credentials ]${COLOR_RESET}"
    echo -e "  5. NTLM (Windows SAM / Active Directory)"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 1000 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e "  6. Linux SHA512-Crypt (\$6\$)"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 1800 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e "  7. bcrypt (\$2a\$ / \$2b\$)"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 3200 ${target_file} <wordlist>${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ Network & Domain Authentication ]${COLOR_RESET}"
    echo -e "  8. WPA/WPA2 PMKID / EAPOL"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 22000 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e "  9. Kerberos 5 TGS-REP (Kerberoasting - krb5tgs)"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 13100 ${target_file} <wordlist>${COLOR_RESET}\n"

    echo -e "${COLOR_YELLOW}[ Encrypted Archives & Documents ]${COLOR_RESET}"
    echo -e " 10. ZIP / PKZIP"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 13600 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e " 11. RAR5"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 13000 ${target_file} <wordlist>${COLOR_RESET}"
    echo -e " 12. PDF 1.4 - 1.6 (Acrobat 5 - 8)"
    echo -e "     ${COLOR_CYAN}hashcat -a 0 -m 10500 ${target_file} <wordlist>${COLOR_RESET}\n"

    echo -e "${COLOR_BOLD}Usage:${COLOR_RESET} hashcat [profile_num|hash_file] [profile_num] [wordlist_path]"
    echo -e "${COLOR_BOLD}Examples:${COLOR_RESET}"
    echo -e "  - ${COLOR_CYAN}hashcat hashes.txt 1${COLOR_RESET}                          : Crack hashes.txt using Profile 1 (MD5) & Wordlist picker"
    echo -e "  - ${COLOR_CYAN}hashcat hashes.txt 5 /usr/share/wordlists/...${COLOR_RESET} : Crack hashes.txt using Profile 5 (NTLM) & specified wordlist"
    echo -e "  - ${COLOR_CYAN}hashcat 1 hashes.txt${COLOR_RESET}                          : Crack hashes.txt using Profile 1 (MD5)"
    echo -e "  - ${COLOR_CYAN}hashcat${COLOR_RESET}                                   : Open interactive profile & file wizard\n"
}

run_hashcat() {
    local arg1="${1:-}"
    local arg2="${2:-}"
    local arg3="${3:-}"

    # Target-independent help
    if [[ "${arg1,,}" == "?" || "${arg1,,}" == "help" || "${arg1,,}" == "-h" || "${arg1,,}" == "--help" ]]; then
        show_hashcat_help "${arg2:-<hash_file>}"
        return 0
    fi

    local hash_file=""
    local profile_num=""
    local custom_wordlist=""

    # Parsing arguments smartly
    if [[ -n "${arg1}" ]]; then
        eval expanded_arg1="${arg1}"
        if [[ -f "${expanded_arg1}" ]]; then
            hash_file="${expanded_arg1}"
            profile_num="${arg2:-1}"
            custom_wordlist="${arg3:-}"
        elif [[ "${arg1}" =~ ^[0-9]+$ || "${arg1,,}" =~ ^(md5|sha1|sha256|sha512|ntlm|linux|bcrypt|wpa|kerberos|zip|rar|pdf)$ ]]; then
            profile_num="${arg1}"
            if [[ -n "${arg2}" ]]; then
                eval hash_file="${arg2}"
            fi
            custom_wordlist="${arg3:-}"
        fi
    fi

    # Interactive prompt for hash file if not provided or missing
    if [[ -z "${hash_file}" || ! -f "${hash_file}" ]]; then
        if [[ -n "${hash_file}" && ! -f "${hash_file}" ]]; then
            print_error "Hash file not found: '${hash_file}'"
        fi

        echo -e "\n${COLOR_BOLD}--- Hashcat Target File Selection ---${COLOR_RESET}"
        echo -en "${COLOR_CYAN}Enter path to Hash File (or type 'back'): ${COLOR_RESET}"
        local read_status=0
        read -r hash_file || read_status=$?

        if [[ ${read_status} -gt 128 ]]; then
            echo ""
            return 0
        fi

        hash_file="$(echo "${hash_file}" | awk '{$1=$1;print}')"
        local lower_hash_file="${hash_file,,}"

        if [[ "${lower_hash_file}" == "0" || "${lower_hash_file}" == "b" || "${lower_hash_file}" == "back" || -z "${hash_file}" ]]; then
            print_info "Navigating back to vash shell..."
            return 0
        fi

        eval hash_file="${hash_file}"
        if [[ ! -f "${hash_file}" ]]; then
            print_error "File not found: '${hash_file}'"
            return 0
        fi
    fi

    # Interactive prompt for profile selection if not provided
    if [[ -z "${profile_num}" ]]; then
        menu_header "${TARGET:-No Target Set}"
        show_hashcat_help "${hash_file}"
        echo -e "  0. Back to vash Shell (or type 'back')\n"
        echo -en "${COLOR_CYAN}Select Hashcat Profile Option [1-12 / type 'back']: ${COLOR_RESET}"

        local read_status=0
        read -r profile_num || read_status=$?

        if [[ ${read_status} -gt 128 ]]; then
            echo ""
            return 0
        fi

        profile_num="$(echo "${profile_num}" | awk '{$1=$1;print}')"
        local lower_profile="${profile_num,,}"

        if [[ "${lower_profile}" == "0" || "${lower_profile}" == "b" || "${lower_profile}" == "back" || -z "${profile_num}" ]]; then
            print_info "Navigating back to vash shell..."
            return 0
        fi
    fi

    local mode
    mode="$(_get_hashcat_mode "${profile_num}")"
    local title
    title="$(_get_hashcat_title "${profile_num}")"

    # Wordlist Selection Logic
    if [[ -n "${custom_wordlist}" ]]; then
        eval custom_wordlist="${custom_wordlist}"
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

    print_info "Starting Hashcat attack..."
    print_info "Hash File: ${hash_file}"
    print_info "Profile:   ${title}"
    print_info "Mode (-m): ${mode}"
    print_info "Wordlist:  ${SELECTED_WORDLIST}"
    print_info "Command:   hashcat -a 0 -m ${mode} ${hash_file} ${SELECTED_WORDLIST}"
    echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"

    local status=0
    hashcat -a 0 -m "${mode}" "${hash_file}" "${SELECTED_WORDLIST}" || status=$?

    if [[ ${status} -eq 130 || ${status} -gt 128 ]]; then
        echo ""
        return 0
    elif [[ ${status} -ne 0 ]]; then
        print_error "Hashcat execution failed or interrupted."
        pause
    else
        print_success "Hashcat cracking session completed."
        pause
    fi
}
