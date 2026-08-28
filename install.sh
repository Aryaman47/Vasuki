#!/usr/bin/env bash
# install.sh - Installer script for vash / Vasuki

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
    print_info() { echo "[*] $1"; }
    print_success() { echo "[+] $1"; }
    print_error() { echo "[-] $1" >&2; }
fi

print_info "Starting vash (Vasuki Shell) installation..."

# Check required dependencies
deps=("nmap" "ffuf" "curl" "hashcat")
missing=()
for dep in "${deps[@]}"; do
    if ! command -v "${dep}" >/dev/null 2>&1; then
        missing+=("${dep}")
    fi
done

if [[ ${#missing[@]} -ne 0 ]]; then
    print_error "Missing required dependencies: ${missing[*]}"
    print_info "Please install them before running vash."
fi

# Create persistent user config directory & history files
VASUKI_CONFIG_DIR="${HOME}/.config/vasuki"
mkdir -p "${VASUKI_CONFIG_DIR}"
touch "${VASUKI_CONFIG_DIR}/saved_wordlists.txt"
touch "${VASUKI_CONFIG_DIR}/target_history.txt"
touch "${VASUKI_CONFIG_DIR}/command_history.txt"

# Determine target directories (root vs non-root)
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    BIN_DIR="/usr/local/bin"
    SHARE_DIR="/usr/local/share/vasuki"
else
    BIN_DIR="${HOME}/.local/bin"
    SHARE_DIR="${HOME}/.local/share/vasuki"
fi

print_info "Installing files to ${SHARE_DIR}..."
mkdir -p "${BIN_DIR}" "${SHARE_DIR}"

# Copy files
cp -r "${SCRIPT_DIR}/"* "${SHARE_DIR}/" 2>/dev/null || true

# Set executable permissions
chmod +x "${SHARE_DIR}/Vasuki"
chmod +x "${SHARE_DIR}/config.sh" "${SHARE_DIR}/common.sh" "${SHARE_DIR}/nmap.sh" "${SHARE_DIR}/ffuf.sh" "${SHARE_DIR}/curl.sh" "${SHARE_DIR}/hashcat.sh" "${SHARE_DIR}/seclists.sh"
chmod +x "${SHARE_DIR}/install.sh" "${SHARE_DIR}/uninstall.sh" 2>/dev/null || true

# Symlink executables: vash and vasuki
ln -sf "${SHARE_DIR}/Vasuki" "${BIN_DIR}/vash"
ln -sf "${SHARE_DIR}/Vasuki" "${BIN_DIR}/vasuki"

print_success "vash (Vasuki Shell) installed successfully!"
print_info "Executable symlinks created:"
print_info "  - ${BIN_DIR}/vash"
print_info "  - ${BIN_DIR}/vasuki"
print_info "Run 'vash' or 'vasuki' from any terminal session."
