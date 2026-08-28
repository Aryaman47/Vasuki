#!/usr/bin/env bash
# common.sh - Shared helper functions for vash (Vasuki Shell)

banner() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    cat << "EOF"
  ██╗   ██╗ █████╗ ███████╗██╗   ██╗██╗  ██╗██╗
  ██║   ██║██╔══██╗██╔════╝██║   ██║██║ ██╔╝██║
  ██║   ██║███████║███████╗██║   ██║█████╔╝ ██║
  ╚██╗ ██╔╝██╔══██║╚════██║██║   ██║██╔═██╗ ██║
   ╚████╔╝ ██║  ██║███████║╚██████╔╝██║  ██╗██║
    ╚═══╝  ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝
EOF
    echo -e "${COLOR_RESET}"
    echo -e "${COLOR_BLUE}      vash (Vasuki Shell) Interactive Console v${VERSION}${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}  Type 'help' or '?' for built-in commands | Pass Linux commands directly${COLOR_RESET}\n"
}

pause() {
    echo -en "${COLOR_YELLOW}\nPress [Enter] key to continue...${COLOR_RESET}"
    local status=0
    read -r || status=$?
    if [[ ${status} -gt 128 ]]; then
        echo ""
    fi
}

print_error() {
    local msg="$1"
    echo -e "${COLOR_RED}[-] ERROR: ${msg}${COLOR_RESET}" >&2
}

print_success() {
    local msg="$1"
    echo -e "${COLOR_GREEN}[+] SUCCESS: ${msg}${COLOR_RESET}"
}

print_warning() {
    local msg="$1"
    echo -e "${COLOR_YELLOW}[!] WARNING: ${msg}${COLOR_RESET}"
}

print_info() {
    local msg="$1"
    echo -e "${COLOR_BLUE}[*] INFO: ${msg}${COLOR_RESET}"
}

get_prompt_pwd() {
    local cur_dir="${PWD}"
    if [[ "${cur_dir}" == "${HOME}"* ]]; then
        cur_dir="~${cur_dir#${HOME}}"
    fi
    echo "${cur_dir}"
}

validate_target() {
    local target="$1"

    if [[ -z "${target}" ]]; then
        print_error "Target cannot be empty."
        return 1
    fi

    if [[ ! "${target}" =~ ^([a-zA-Z0-9]+://)?[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
        print_error "Invalid target format: '${target}'"
        return 1
    fi

    return 0
}

normalize_target() {
    local target="$1"

    target="${target%/}"

    if [[ ! "${target}" =~ :// ]]; then
        target="${DEFAULT_PROTOCOL}://${target}"
    fi

    echo "${target}"
}

extract_host() {
    local raw_target="$1"
    local host="${raw_target#*://}"
    host="${host%%/*}"
    host="${host%%:*}"
    echo "${host}"
}

export_target_environment() {
    local raw_target="$1"
    if [[ -n "${raw_target}" ]]; then
        export TARGET="${raw_target}"
        export URL="${raw_target}"
        export HOST="$(extract_host "${raw_target}")"
        export IP="${HOST}"
    else
        unset TARGET URL HOST IP 2>/dev/null || true
    fi
}

save_target_history() {
    local target="$1"
    mkdir -p "${VASUKI_CONFIG_DIR}"
    touch "${TARGET_HISTORY_FILE}"

    if ! grep -Fxq "${target}" "${TARGET_HISTORY_FILE}" 2>/dev/null; then
        echo "${target}" >> "${TARGET_HISTORY_FILE}"
    fi
}

show_target_history() {
    mkdir -p "${VASUKI_CONFIG_DIR}"
    touch "${TARGET_HISTORY_FILE}"

    echo -e "\n${COLOR_BOLD}=== Saved Target History ===${COLOR_RESET}"
    if [[ ! -s "${TARGET_HISTORY_FILE}" ]]; then
        print_info "No targets logged in history yet."
        return 0
    fi

    local i=1
    while IFS= read -r t; do
        if [[ -n "${t}" ]]; then
            printf "%3d) %s\n" "${i}" "${t}"
            ((i++))
        fi
    done < "${TARGET_HISTORY_FILE}"
    echo -e "${COLOR_CYAN}Tip: Type 'target <num>' to select a target by history number.${COLOR_RESET}\n"
}

show_command_history() {
    mkdir -p "${VASUKI_CONFIG_DIR}"
    touch "${COMMAND_HISTORY_FILE}"

    echo -e "\n${COLOR_BOLD}=== Recent Command History ===${COLOR_RESET}"
    if [[ ! -s "${COMMAND_HISTORY_FILE}" ]]; then
        print_info "No commands logged in history yet."
        return 0
    fi

    tail -n 25 "${COMMAND_HISTORY_FILE}" | nl -w 3 -s ') '
    echo ""
}

show_help() {
    echo -e "\n${COLOR_BOLD}=== vash (Vasuki Shell) Built-in Commands ===${COLOR_RESET}"
    printf "  %-25s %s\n" "target <URL|IP>" "Set or change the active target"
    printf "  %-25s %s\n" "target <num>" "Select target by number from history log"
    printf "  %-25s %s\n" "targets" "Display target history log"
    printf "  %-25s %s\n" "show target" "Display current target & environment variables"
    printf "  %-25s %s\n" "nmap [profile_num]" "Run Nmap scanner module or specific profile"
    printf "  %-25s %s\n" "nmap ?" "Display Nmap scan profiles reference"
    printf "  %-25s %s\n" "ffuf [wordlist_path]" "Run FFUF fuzzing module or specific wordlist"
    printf "  %-25s %s\n" "ffuf ?" "Display FFUF fuzzing module reference"
    printf "  %-25s %s\n" "curl [option_num]" "Run Curl toolkit module or specific request"
    printf "  %-25s %s\n" "curl ?" "Display Curl toolkit module reference"
    printf "  %-25s %s\n" "hashcat [file] [prof]" "Run Hashcat offline password cracking module"
    printf "  %-25s %s\n" "hashcat ?" "Display Hashcat attack profiles reference"
    printf "  %-25s %s\n" "cd [dir]" "Change working directory"
    printf "  %-25s %s\n" "history [commands|targets]" "Display command or target history"
    printf "  %-25s %s\n" "clear / cls" "Clear terminal screen and re-render header"
    printf "  %-25s %s\n" "help / ?" "Display this command reference table"
    printf "  %-25s %s\n" "exit / quit / back" "Exit vash interactive shell"
    echo -e "\n${COLOR_YELLOW}Linux Command Passthrough:${COLOR_RESET}"
    echo -e "  Any command not listed above is executed directly as a Linux shell command."
    echo -e "  Environment variables available: ${COLOR_CYAN}\$TARGET, \$URL, \$HOST, \$IP${COLOR_RESET}"
    echo -e "  Examples: ${COLOR_CYAN}ping -c 4 \$HOST${COLOR_RESET} | ${COLOR_CYAN}whois \$HOST${COLOR_RESET} | ${COLOR_CYAN}nikto -h \$URL${COLOR_RESET}\n"
}

check_dependencies() {
    local missing=()
    local deps=("nmap" "ffuf" "curl" "hashcat")

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            missing+=("${dep}")
        fi
    done

    if [[ ${#missing[@]} -ne 0 ]]; then
        print_error "Missing required dependencies: ${missing[*]}"
        print_info "Please install missing packages and rerun vash."
        exit 1
    fi
}

display_main_options() {
    echo -e "${COLOR_BOLD}Available Modules & Commands:${COLOR_RESET}"
    echo "  - nmap         : Run Nmap Port Scanning profiles (type 'nmap ?' for help)"
    echo "  - ffuf         : Run FFUF Directory/File Fuzzing (type 'ffuf ?' for help)"
    echo "  - curl         : Run Curl HTTP Toolkit (type 'curl ?' for help)"
    echo "  - hashcat      : Run Hashcat Password Cracking (type 'hashcat ?' for help)"
    echo "  - target <URL> : Set/Change Target"
    echo "  - targets      : View Target History"
    echo "  - history      : View Command History"
    echo "  - help         : View Full vash Help Table"
    echo "  - exit         : Exit vash Shell"
    echo ""
}

save_wordlist_path() {
    local path="$1"
    mkdir -p "${VASUKI_CONFIG_DIR}"
    touch "${SAVED_WORDLISTS_FILE}"

    if ! grep -Fxq "${path}" "${SAVED_WORDLISTS_FILE}" 2>/dev/null; then
        echo "${path}" >> "${SAVED_WORDLISTS_FILE}"
        print_info "Saved wordlist path to history: ${path}"
    fi
}

select_wordlist() {
    SELECTED_WORDLIST=""
    mkdir -p "${VASUKI_CONFIG_DIR}"
    touch "${SAVED_WORDLISTS_FILE}"

    while true; do
        echo -e "\n${COLOR_BOLD}--- Wordlist Selection ---${COLOR_RESET}"

        local saved_paths=()
        if [[ -f "${SAVED_WORDLISTS_FILE}" ]]; then
            while IFS= read -r line; do
                [[ -n "${line}" ]] && saved_paths+=("${line}")
            done < "${SAVED_WORDLISTS_FILE}"
        fi

        local option_num=1
        if [[ ${#saved_paths[@]} -gt 0 ]]; then
            echo -e "${COLOR_YELLOW}Saved Wordlists:${COLOR_RESET}"
            for p in "${saved_paths[@]}"; do
                echo "${option_num}. ${p}"
                ((option_num++))
            done
            echo ""
        fi

        local enter_new_option="${option_num}"
        echo "${enter_new_option}. Enter new wordlist path"
        ((option_num++))

        local seclists_option="${option_num}"
        echo "${seclists_option}. Browse SecLists Web-Content (/usr/share/wordlists/...)"
        echo "0. Back to vash Shell (or type 'back')"

        echo -en "\n${COLOR_CYAN}Select Wordlist Option [1-${seclists_option}] (or type path / 'back'): ${COLOR_RESET}"

        local read_status=0
        read -r input_choice || read_status=$?

        if [[ ${read_status} -gt 128 ]]; then
            echo ""
            return 1
        fi

        input_choice="$(echo "${input_choice}" | awk '{$1=$1;print}')"
        local lower_choice="${input_choice,,}"

        if [[ "${lower_choice}" == "0" || "${lower_choice}" == "b" || "${lower_choice}" == "back" ]]; then
            print_info "Navigating back to vash shell..."
            return 1
        fi

        if [[ "${input_choice}" =~ ^~ || "${input_choice}" =~ ^/ || "${input_choice}" =~ \. || "${input_choice}" =~ / ]]; then
            local direct_path="${input_choice}"
            eval direct_path="${direct_path}"

            if [[ -f "${direct_path}" ]]; then
                save_wordlist_path "${direct_path}"
                SELECTED_WORDLIST="${direct_path}"
                print_success "Selected wordlist: ${SELECTED_WORDLIST}"
                return 0
            elif [[ -d "${direct_path}" ]]; then
                print_error "'${direct_path}' is a directory, not a wordlist file."
                continue
            else
                print_error "File not found: '${direct_path}'"
                continue
            fi
        fi

        if [[ ! "${input_choice}" =~ ^[0-9]+$ ]] || (( input_choice < 1 || input_choice > seclists_option )); then
            print_error "Invalid selection. Enter option [1-${seclists_option}], path, or type 'back'."
            continue
        fi

        local choice="${input_choice}"

        if [[ ${#saved_paths[@]} -gt 0 ]] && (( choice <= ${#saved_paths[@]} )); then
            local chosen_path="${saved_paths[$((choice - 1))]}"
            if [[ -f "${chosen_path}" ]]; then
                SELECTED_WORDLIST="${chosen_path}"
                print_success "Selected wordlist: ${SELECTED_WORDLIST}"
                return 0
            else
                print_error "Saved wordlist file no longer exists: '${chosen_path}'"
                continue
            fi
        elif [[ "${choice}" -eq "${enter_new_option}" ]]; then
            while true; do
                echo -en "${COLOR_CYAN}Enter wordlist path (or type 'back' to return to Wordlist Selection): ${COLOR_RESET}"
                local sub_read_status=0
                read -r new_path || sub_read_status=$?

                if [[ ${sub_read_status} -gt 128 ]]; then
                    echo ""
                    return 1
                fi

                new_path="$(echo "${new_path}" | awk '{$1=$1;print}')"
                local lower_new_path="${new_path,,}"

                if [[ "${lower_new_path}" == "0" || "${lower_new_path}" == "b" || "${lower_new_path}" == "back" ]]; then
                    print_info "Navigating back to Wordlist Selection..."
                    break
                fi

                if [[ -z "${new_path}" ]]; then
                    print_error "Wordlist path cannot be empty."
                    continue
                fi

                eval new_path="${new_path}"

                if [[ -f "${new_path}" ]]; then
                    save_wordlist_path "${new_path}"
                    SELECTED_WORDLIST="${new_path}"
                    print_success "Selected wordlist: ${SELECTED_WORDLIST}"
                    return 0
                elif [[ -d "${new_path}" ]]; then
                    print_error "'${new_path}' is a directory, not a wordlist file."
                else
                    print_error "File not found: '${new_path}'"
                fi
            done
        elif [[ "${choice}" -eq "${seclists_option}" ]]; then
            if [[ -f "${SCRIPT_DIR}/seclists.sh" ]]; then
                # shellcheck source=seclists.sh
                source "${SCRIPT_DIR}/seclists.sh"
                if select_seclist_wordlist; then
                    if [[ -n "${SELECTED_WORDLIST:-}" ]]; then
                        save_wordlist_path "${SELECTED_WORDLIST}"
                        return 0
                    fi
                fi
                continue
            else
                print_error "seclists.sh script not found at ${SCRIPT_DIR}/seclists.sh"
                continue
            fi
        fi
    done
}

menu_header() {
    local target="$1"
    clear || true
    banner
    echo -e "${COLOR_BOLD}=============================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD} Current Target: ${COLOR_GREEN}${target:-No Target Set}${COLOR_RESET}"
    echo -e "${COLOR_BOLD} Current Dir:    ${COLOR_BLUE}$(get_prompt_pwd)${COLOR_RESET}"
    echo -e "${COLOR_BOLD}=============================================${COLOR_RESET}\n"
}
