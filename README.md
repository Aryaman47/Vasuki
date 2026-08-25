# `vash` (Vasuki Shell) Architectural & Technical Specification

## Project Overview

`vash` (**Vasuki Shell**) is a modular, interactive Read-Eval-Print Loop (REPL) reconnaissance console written in Bash. It automates common security tasks around underlying tools (`nmap`, `ffuf`, `curl`) while providing a shell interface featuring:

- **Stateful Target anagement**: Tracks an active target string across tool invocations and exports environment variables (`$TARGET`, `$URL`, `$HOST`, `$IP`).
- **Dynamic Prompt Formatting**: Displays target status and current working directory in the prompt (e.g. `vash(http://10.10.10.10):~/Projects >`).
- **Native Linux Passthrough**: Automatically evaluates non-builtin commands in the host environment with target variables bound.
- **Persistent State Logging**: Retains command history, target history, and user-provided wordlist paths under `~/.config/vasuki/`.
- **Target-Independent Sub-Module Help**: Displays tool profile references without requiring an active target (`nmap ?`, `ffuf ?`, `curl ?`).

---

## High-Level System Architecture

```
                       +-----------------------------------+
                       |    vash Launcher (Vasuki)         |
                       |  - Readline Loop (vash_repl)      |
                       |  - Signal Traps (SIGINT/SIGTERM)  |
                       +-----------------+-----------------+
                                         |
                                         v
                       +-----------------------------------+
                       |    Core Subsystems (common.sh)    |
                       |  - Target Normalization & Export  |
                       |  - History Log Managers           |
                       |  - Interactive Wordlist Picker    |
                       +-----------------+-----------------+
                                         |
         +-------------------------------+-------------------------------+
         |                               |                               |
         v                               v                               v
+------------------+           +-------------------+           +-------------------+
|   Nmap Module    |           |    FFUF Module    |           |    Curl Module    |
|   (nmap.sh)      |           |    (ffuf.sh)      |           |    (curl.sh)      |
+------------------+           +---------+---------+           +-------------------+
                                         |
                                         v
                               +-------------------+
                               |  SecLists Finder  |
                               |   (seclists.sh)   |
                               +-------------------+
```

---

## File Hierarchy & Responsibilities

| File | Purpose & Primary Responsibilities |
| :--- | :--- |
| `Vasuki` | **Main Entry Point & REPL Launcher**: Initializes signal handlers, executes dependency checks, manages readline command loops, handles target switching, routes built-in commands, and passes unhandled commands to host shell. |
| `config.sh` | **Central Configuration Store**: Defines program constants (`PROGRAM_NAME`, `SHELL_NAME`, `VERSION`), persistent directory paths (`VASUKI_CONFIG_DIR`, `TARGET_HISTORY_FILE`, `COMMAND_HISTORY_FILE`, `SAVED_WORDLISTS_FILE`), and ANSI color tokens. |
| `common.sh` | **Core Helper Library**: Contains UI formatting functions (`banner`, `menu_header`), input validation/normalization routines (`validate_target`, `normalize_target`), target environment exporter (`export_target_environment`), persistent logging logic, and the interactive wordlist selector (`select_wordlist`). |
| `nmap.sh` | **Nmap Module**: Exposes `run_nmap()`. Extracts clean hostnames/IPs from target URLs, handles direct profile arguments (e.g. `nmap 1`), renders categorized scan profiles (Basic, Moderate, Advanced), and executes `nmap ?` help reference without target prerequisites. |
| `ffuf.sh` | **FFUF Module**: Exposes `run_ffuf()`. Constructs `/FUZZ` URLs, coordinates with `common.sh` and `seclists.sh` for wordlist resolution, supports direct wordlist file paths, and executes `ffuf ?` help reference. |
| `curl.sh` | **Curl Module**: Exposes `run_curl()`. Renders request options (GET, `-i`, `-I`, `-v`), supports direct flags/arguments (e.g. `curl -i`), and executes `curl ?` help reference. |
| `seclists.sh` | **SecLists Discovery Utility**: Standalone and imported helper. Scans system paths for SecLists Web-Content wordlists (`/usr/share/wordlists/seclists/...`), renders indexed pickers, and returns absolute wordlist paths. |
| `install.sh` | **Installer Script**: Validates system dependencies (`nmap`, `ffuf`, `curl`), initializes configuration directory structure under `~/.config/vasuki/`, copies project files to binary share paths (`/usr/local/share/vasuki` or `~/.local/share/vasuki`), and configures executable symlinks (`vash` & `vasuki`). |
| `uninstall.sh` | **Uninstaller Script**: Removes installed binary symlinks (`vash` & `vasuki`) and shared program directories while preserving user data under `~/.config/vasuki/`. |

---

## Detailed Component Specifications

### 1. Target Processing Pipeline

Targets passed to `vash` (e.g. `example.com`, `10.10.10.10`, `https://example.com/blog`) undergo normalization before module dispatch:

- **Validation**: Verified against regular expression `^([a-zA-Z0-9]+://)?[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$` in `validate_target()`.
- **Normalization**: Trailing slashes are stripped. If missing a scheme, `DEFAULT_PROTOCOL` (`http://`) is prepended in `normalize_target()`.
- **Environment Export**: `export_target_environment()` extracts components and sets environment variables:
  - `TARGET`: Full normalized string (e.g. `http://example.com/blog`)
  - `URL`: Alias of `$TARGET`
  - `HOST`: Extracted hostname/IP (e.g. `example.com`)
  - `IP`: Alias of `$HOST`

### 2. Module Specifications

#### Nmap Module (`nmap.sh`)
Executes scan profiles against `$HOST`. Profiles are categorized into three intensity levels:

- **Basic**:
  1. Fast Scan (`nmap -F <target>`)
  2. Ping Discovery (`nmap -sn <target>`)
  3. Top 1000 Ports (`nmap <target>`)
- **Moderate**:
  4. Service Version Detection (`nmap -sV <target>`)
  5. Default Scripts & Version Detection (`nmap -sC -sV <target>`)
  6. OS & Version Detection (`nmap -O -sV <target>`)
  7. SYN Stealth Scan (`nmap -sS -sV <target>`)
- **Advanced**:
  8. Aggressive Scan (`nmap -A <target>`)
  9. Full Port Scan (`nmap -p- -sC -sV <target>`)
  10. UDP Top Ports Scan (`nmap -sU --top-ports 100 <target>`)
  11. Vulnerability Assessment (`nmap --script vuln <target>`)

#### FFUF Module (`ffuf.sh`)
- Appends `/FUZZ` to the active URL if no `FUZZ` placeholder is present.
- Resolves wordlists via `select_wordlist()`, direct argument pathing (`ffuf /path/to/wordlist.txt`), or system SecLists discovery.
- Appends verified user paths to `~/.config/vasuki/saved_wordlists.txt` for future quick selection.

#### Curl Module (`curl.sh`)
Renders interactive HTTP request options (`GET`, `-i` Include Headers, `-I` HEAD, `-v` Verbose) or passes custom curl arguments directly (`curl -i`).

---

## State & Persistent Data Management

All persistent state is stored in standard user configuration paths under `~/.config/vasuki/`:

```
~/.config/vasuki/
├── command_history.txt   # Appended history of all executed shell commands
├── target_history.txt    # Uniquely logged list of valid targets
└── saved_wordlists.txt   # Saved list of user-provided wordlist paths
```

---

## Command Reference Table

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `target` | `<URL\|IP>` or `<num>` | Sets target explicitly, or selects item `<num>` from target history log. |
| `targets` | *None* | Displays numbered log of previously set targets. |
| `show` | `target` \| `options` | Displays active target variables (`$TARGET`, `$HOST`, `$URL`, `$IP`, `$PWD`) or main module options. |
| `nmap` | `[1-11]` \| `?` | Opens Nmap profiles menu, executes profile `[1-11]` directly, or displays profile help (`nmap ?`). |
| `ffuf` | `[wordlist_path]` \| `?` | Opens Wordlist picker, executes fuzzing with specified file path, or displays FFUF help (`ffuf ?`). |
| `curl` | `[1-4]` \| `[flags]` \| `?` | Opens Curl menu, executes specific request profile, or displays Curl help (`curl ?`). |
| `cd` | `[dir]` | Changes working directory in-process and updates prompt path representation (`~`). |
| `history` | `[commands\|targets]` | Displays command history log or target history log. |
| `clear` / `cls` | *None* | Clears terminal screen and re-renders vash header. |
| `help` / `?` | *None* | Renders built-in command reference table. |
| `exit` / `quit` | *None* | Terminates vash interactive shell session. |


---

## Comprehensive Source Code Analysis & Logic Explanation

This section provides a granular, line-by-line and logic-block breakdown of every Bash script in the Vasuki (`vash`) repository.

---

### 1. `Vasuki` (Main REPL Entry Point)

#### Core Role & Initialization
The `Vasuki` script serves as the primary launcher and interactive REPL engine for `vash`. It initializes shell behavior, sources dependency modules, sets up signal traps, and maintains the primary command loop.

#### Key Logic Components

##### A. Interpreter & Execution Flags
- `#!/usr/bin/env bash`: Ensures portability across Linux environments.
- `set -Eeuo pipefail`: Configures strict mode during initialization (trap inherited, exit on error, fail on pipeline errors). Note that `set +e` is toggled inside `vash_repl()` so interactive errors do not terminate the shell.

##### B. Symlink & Directory Resolution
- `SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"`: Resolves the absolute physical path of the script directory even when invoked via symlink (`vash` or `vasuki` in `/usr/local/bin` or `~/.local/bin`).

##### C. Signal Handling (`trap`)
- `trap cleanup SIGTERM`: Gracefully exits the shell on termination signals.
- `trap trap_sigint SIGINT`: Intercepts `Ctrl+C` (`SIGINT`) to print `[!] Interrupted. Returning to vash prompt...` without exiting the shell process.

##### D. Target Setting (`set_target_interactive` & `prompt_target_input`)
- `set_target_interactive()`: Validates target string or index number. If a number is passed (e.g. `target 1`), it retrieves line `N` from `~/.config/vasuki/target_history.txt`. On valid targets, it normalizes the URL, calls `export_target_environment()`, and logs to target history.
- `prompt_target_input()`: Interactively prompts for a target if non-target mode is initialized.

##### E. REPL Core (`vash_repl`)
- Initializes Readline history with `history -r "${COMMAND_HISTORY_FILE}"`.
- Dynamically renders prompt: `vash(${CURRENT_TARGET}):${PWD} > ` (with `~` path substitution via `get_prompt_pwd()`).
- Parses input line into `cmd` and `args`.
- Appends command input to `COMMAND_HISTORY_FILE` and Readline buffer (`history -s`).
- Dispatches built-in commands (`target`, `targets`, `show`, `nmap`, `ffuf`, `curl`, `cd`, `history`, `clear`, `help`, `exit`).
- **Native Command Passthrough**: Unhandled commands are evaluated using `eval "${input_line}"` with `$TARGET`, `$URL`, `$HOST`, `$IP` exported to the execution environment.

---

### 2. `config.sh` (Central Configuration Store)

#### Core Role
`config.sh` centralizes global constants, file paths, default protocols, and ANSI color tokens used across all modules.

#### Key Variables Defined
- `PROGRAM_NAME="Vasuki"`, `SHELL_NAME="vash"`, `VERSION="2.0.0"`: Versioning and program branding metadata.
- `VASUKI_CONFIG_DIR="${HOME}/.config/vasuki"`: User-level configuration directory.
- `SAVED_WORDLISTS_FILE`: `${VASUKI_CONFIG_DIR}/saved_wordlists.txt`
- `TARGET_HISTORY_FILE`: `${VASUKI_CONFIG_DIR}/target_history.txt`
- `COMMAND_HISTORY_FILE`: `${VASUKI_CONFIG_DIR}/command_history.txt`
- `DEFAULT_PROTOCOL="http"`: Default scheme applied during target normalization.
- `COLOR_*`: ANSI color code constants (`COLOR_RED`, `COLOR_GREEN`, `COLOR_YELLOW`, `COLOR_BLUE`, `COLOR_CYAN`, `COLOR_BOLD`, `COLOR_RESET`) toggled based on `COLOR_ENABLED`.

---

### 3. `common.sh` (Shared Helper Library & Utilities)

#### Core Role
`common.sh` provides shared utility functions for UI rendering, target validation, target normalization, environment variable exporting, persistent logging, and interactive wordlist selection.

#### Key Functions Breakdown

##### A. Visual & UI Helpers
- `banner()`: Prints ASCII art logo, version number, and quick start guidance.
- `pause()`: Suspends execution until the user presses Enter.
- `print_error()`, `print_success()`, `print_warning()`, `print_info()`: Standardized color-coded logging routines.
- `menu_header()`: Clears screen and displays standard current target & working directory banner.

##### B. Target Normalization & Environment Binding
- `validate_target()`: Validates input string against IP/hostname/URL regex format.
- `normalize_target()`: Strips trailing slashes and prepends `http://` if no protocol scheme is specified.
- `extract_host()`: Strips protocol scheme, port numbers, and URL paths to isolate pure hostname/IP.
- `export_target_environment()`: Populates environment variables `$TARGET`, `$URL`, `$HOST`, and `$IP` for host command passthrough.

##### C. History Management
- `save_target_history()`: Appends unique target strings to `target_history.txt`.
- `show_target_history()`: Displays numbered log of previously targeted hosts/URLs.
- `show_command_history()`: Displays the last 25 commands from `command_history.txt`.
- `show_help()`: Renders full reference table of `vash` built-in commands.

##### D. Interactive Wordlist Selector (`select_wordlist`)
- Reads persistent user wordlist paths from `saved_wordlists.txt`.
- Renders numbered selection menu combining saved paths, option for new path input, option for SecLists browsing, and `0` / `back` navigation.
- **Smart Direct Path Detection**: Auto-detects if a user pastes/types a file path directly at the choice prompt (`/usr/share/...` or `~/...`).
- **Directory Validation**: Explicitly catches directory inputs (e.g. `/usr/share/wordlists`) and warns the user instead of failing silently.
- **Dedicated Path Retry Loop**: Retains path entry prompt on input errors so users can fix typos without returning to option selection.

---

### 4. `nmap.sh` (Nmap Enumeration Module)

#### Core Role
Provides Nmap service scanning capabilities organized into 3 scan intensity levels, supporting interactive menus, direct profile argument execution, and target-independent help.

#### Key Functions & Logic

##### A. Target-Independent Help (`show_nmap_help`)
- Renders categorized scan profiles (Basic 1–3, Moderate 4–7, Advanced 8–11) along with scan titles and exact `nmap` commands.
- Operates without requiring an active target when called via `nmap ?` or `nmap help`.

##### B. Scan Execution (`run_nmap`)
- Extracts clean host/IP via `_extract_nmap_target()`.
- Supports direct profile numbers (e.g. `nmap 1` -> `nmap -F <host>`).
- Executes selected `nmap` scan command and handles return status gracefully.

---

### 5. `ffuf.sh` (FFUF Directory & File Fuzzing Module)

#### Core Role
Manages web directory and file fuzzing using `ffuf`.

#### Key Functions & Logic

##### A. URL Construction (`_prepare_ffuf_url`)
- Checks if the active target URL contains the `FUZZ` placeholder.
- If missing, automatically appends `/FUZZ` (e.g. `http://10.10.10.10/admin` -> `http://10.10.10.10/admin/FUZZ`).

##### B. Execution & Wordlist Binding (`run_ffuf`)
- Supports direct wordlist arguments (`ffuf /path/to/dict.txt`) or interactive wordlist selection (`select_wordlist`).
- Logs new valid wordlist paths to `saved_wordlists.txt`.
- Supports target-independent help (`ffuf ?`).

---

### 6. `curl.sh` (Curl HTTP Toolkit Module)

#### Core Role
Executes common HTTP requests against the active target URL.

#### Key Functions & Logic
- Renders request profiles:
  1. GET (`curl <target>`)
  2. Include Headers (`curl -i <target>`)
  3. HEAD Request (`curl -I <target>`)
  4. Verbose Request (`curl -v <target>`)
- Supports direct option selection (`curl 2` or `curl -i`) and custom flags.
- Supports target-independent help (`curl ?`).

---

### 7. `seclists.sh` (SecLists Discovery Utility)

#### Core Role
Locates and indexes SecLists Web-Content wordlists on Linux/Kali systems.

#### Key Functions & Logic
- `locate_seclists_dir()`: Checks standard system locations (`/usr/share/wordlists/seclists/Discovery/Web-Content`, `/usr/share/seclists/...`, `/opt/seclists/...`).
- `select_seclist_wordlist()`: Recursively scans for `.txt` and `.lst` files using `find`, displays a numbered list of relative paths, and returns the selected absolute path.

---

### 8. `install.sh` (System Installation & Symlink Provisioner)

#### Core Role
Deploys Vasuki/vash onto the system environment.

#### Key Actions
1. Verifies binary dependencies (`nmap`, `ffuf`, `curl`).
2. Creates persistent configuration folder `~/.config/vasuki/` and initializes state tracking files.
3. Copies project files to `/usr/local/share/vasuki` (root) or `~/.local/share/vasuki` (user).
4. Grants executable permissions (`chmod +x`).
5. Configures executable symlinks in `/usr/local/bin` or `~/.local/bin`:
   - `vash` -> `${SHARE_DIR}/Vasuki`
   - `vasuki` -> `${SHARE_DIR}/Vasuki`

---

### 9. `uninstall.sh` (Uninstallation Cleanup Script)

#### Core Role
Removes Vasuki/vash from the system environment.

#### Key Actions
1. Removes executable symlinks (`vash` and `vasuki`) from binary path.
2. Removes shared program directory (`/usr/local/share/vasuki` or `~/.local/share/vasuki`).
3. Preserves user configuration data in `~/.config/vasuki/` to prevent history loss.