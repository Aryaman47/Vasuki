#!/usr/bin/env bash
# config.sh - Central configuration settings for vash (Vasuki Shell)

PROGRAM_NAME="Vasuki"
SHELL_NAME="vash"
VERSION="2.0.0"

# Paths & Persistent Config
VASUKI_CONFIG_DIR="${HOME}/.config/vasuki"
SAVED_WORDLISTS_FILE="${VASUKI_CONFIG_DIR}/saved_wordlists.txt"
TARGET_HISTORY_FILE="${VASUKI_CONFIG_DIR}/target_history.txt"
COMMAND_HISTORY_FILE="${VASUKI_CONFIG_DIR}/command_history.txt"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DEFAULT_PROTOCOL="http"

# UI Color configurations
COLOR_ENABLED=true

if [[ "${COLOR_ENABLED}" == "true" ]]; then
    COLOR_RED="\033[0;31m"
    COLOR_GREEN="\033[0;32m"
    COLOR_YELLOW="\033[0;33m"
    COLOR_BLUE="\033[0;34m"
    COLOR_CYAN="\033[0;36m"
    COLOR_BOLD="\033[1m"
    COLOR_RESET="\033[0m"
else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_CYAN=""
    COLOR_BOLD=""
    COLOR_RESET=""
fi