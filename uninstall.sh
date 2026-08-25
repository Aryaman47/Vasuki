#!/usr/bin/env bash
# uninstall.sh - Uninstaller script for vash / Vasuki

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

if [[ -f "${SCRIPT_DIR}/config.sh" ]]; then
    # shellcheck source=config.sh
    source "${SCRIPT_DIR}/config.sh"
fi
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
    # shellcheck source=common.sh
    source "${SCRIPT_DIR}/common.sh"
else
    print_info() { echo "[*] $1"; }
    print_success() { echo "[+] $1"; }
    print_error() { echo "[-] $1" >&2; }
fi

print_info "Starting vash uninstallation..."

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    SHARE_DIR="/usr/local/share/vasuki"
else
    BIN_DIR="${HOME}/.local/bin"
    SHARE_DIR="${HOME}/.local/share/vasuki"
fi

rm -f "${BIN_DIR}/vash" "${BIN_DIR}/vasuki" 2>/dev/null || true

if [[ -d "${SHARE_DIR}" ]]; then
    print_info "Removing installation directory ${SHARE_DIR}..."
    rm -rf "${SHARE_DIR}"
fi

print_success "vash / Vasuki uninstalled successfully."
