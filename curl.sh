#!/usr/bin/env bash
# curl.sh - Curl toolkit module for Vasuki / vash

show_curl_help() {
    local target="${1:-<target_url>}"
    echo -e "\n${COLOR_BOLD}=== Curl Toolkit Module Reference ===${COLOR_RESET}\n"
    echo -e "  1. GET Request              : ${COLOR_CYAN}curl ${target}${COLOR_RESET}"
    echo -e "  2. Include Headers          : ${COLOR_CYAN}curl -i ${target}${COLOR_RESET}"
    echo -e "  3. HEAD Request (Headers)   : ${COLOR_CYAN}curl -I ${target}${COLOR_RESET}"
    echo -e "  4. Verbose Request          : ${COLOR_CYAN}curl -v ${target}${COLOR_RESET}\n"
    echo -e "${COLOR_BOLD}Usage:${COLOR_RESET} curl [option_num|flags]"
    echo -e "${COLOR_BOLD}Examples:${COLOR_RESET} 'curl 2' or 'curl -i' (Include Headers) | 'curl' (Interactive Menu)\n"
}

run_curl() {
    local target="$1"
    local arg="${2:-}"
    local choice=""

    # If help requested, display reference without requiring a target
    if [[ "${arg,,}" == "?" || "${arg,,}" == "help" || "${arg,,}" == "-h" || "${arg,,}" == "--help" ]]; then
        show_curl_help "${target:-<target_url>}"
        return 0
    fi

    if [[ -z "${target}" ]]; then
        print_error "No active target set. Use 'target <URL|IP>' to set a target first, or 'curl ?' for help."
        return 0
    fi

    if [[ -n "${arg}" ]]; then
        case "${arg,,}" in
            1|get)
                print_info "Executing: curl ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl "${target}" || print_error "Curl execution failed."
                ;;
            2|-i|headers|head_inc)
                print_info "Executing: curl -i ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl -i "${target}" || print_error "Curl execution failed."
                ;;
            3|-I|head)
                print_info "Executing: curl -I ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl -I "${target}" || print_error "Curl execution failed."
                ;;
            4|-v|verbose)
                print_info "Executing: curl -v ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl -v "${target}" || print_error "Curl execution failed."
                ;;
            *)
                print_info "Executing: curl ${arg} ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl ${arg} "${target}" || print_error "Curl execution failed."
                ;;
        esac
        return 0
    fi

    while true; do
        menu_header "${target}"
        show_curl_help "${target}"
        echo "0. Back to vash Shell (or type 'back')"
        echo -en "${COLOR_CYAN}Select option [1-4 / type 'back']: ${COLOR_RESET}"

        read -r choice
        choice="$(echo "${choice}" | awk '{$1=$1;print}')"
        local lower_choice="${choice,,}"

        case "${lower_choice}" in
            1)
                print_info "Executing: curl ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl "${target}" || print_error "Curl execution failed."
                pause
                ;;
            2)
                print_info "Executing: curl -i ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl -i "${target}" || print_error "Curl execution failed."
                pause
                ;;
            3)
                print_info "Executing: curl -I ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl -I "${target}" || print_error "Curl execution failed."
                pause
                ;;
            4)
                print_info "Executing: curl -v ${target}"
                echo -e "${COLOR_BOLD}---------------------------------------------${COLOR_RESET}"
                curl -v "${target}" || print_error "Curl execution failed."
                pause
                ;;
            0|5|b|back)
                print_info "Navigating back to vash shell..."
                break
                ;;
            *)
                print_error "Invalid selection. Please choose 1, 2, 3, 4, or type 'back'."
                pause
                ;;
        esac
    done
}
