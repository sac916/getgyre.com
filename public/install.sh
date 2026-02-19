#!/usr/bin/env sh
# Gyre installer
# Usage: curl -fsSL https://getgyre.com/install | sh
# More info: https://getgyre.com/install

set -e

GYRE_VERSION="${GYRE_VERSION:-latest}"
RELEASES_BASE="https://releases.getgyre.com"
INSTALL_DIR="${GYRE_INSTALL_DIR:-/usr/local/bin}"

# ─── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  RED="\033[31m"
  CYAN="\033[36m"
  RESET="\033[0m"
else
  BOLD="" DIM="" GREEN="" YELLOW="" RED="" CYAN="" RESET=""
fi

# ─── Helpers ───────────────────────────────────────────────────────────────────
info()    { printf "${CYAN}info${RESET}  %s\n" "$1"; }
ok()      { printf "${GREEN}✓${RESET}     %s\n" "$1"; }
warn()    { printf "${YELLOW}warn${RESET}  %s\n" "$1" >&2; }
error()   { printf "${RED}error${RESET} %s\n" "$1" >&2; exit 1; }
step()    { printf "\n${BOLD}%s${RESET}\n" "$1"; }

# ─── Detect OS ─────────────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "apple-darwin" ;;
    Linux)  echo "unknown-linux-gnu" ;;
    *)      error "Unsupported OS: $(uname -s). Gyre supports macOS and Linux." ;;
  esac
}

# ─── Detect Architecture ───────────────────────────────────────────────────────
detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "aarch64" ;;
    x86_64)        echo "x86_64" ;;
    *)             error "Unsupported architecture: $(uname -m). Gyre supports arm64 and x86_64." ;;
  esac
}

# ─── Check dependencies ────────────────────────────────────────────────────────
check_deps() {
  if command -v curl > /dev/null 2>&1; then
    DOWNLOADER="curl"
  elif command -v wget > /dev/null 2>&1; then
    DOWNLOADER="wget"
  else
    error "Neither curl nor wget found. Please install one and try again."
  fi
}

# ─── Download binary ───────────────────────────────────────────────────────────
download_binary() {
  local url="$1"
  local dest="$2"

  if [ "$DOWNLOADER" = "curl" ]; then
    curl -fsSL --progress-bar "$url" -o "$dest"
  else
    wget -q --show-progress "$url" -O "$dest"
  fi
}

# ─── Main ──────────────────────────────────────────────────────────────────────
main() {
  printf "\n"
  printf "${BOLD}  Installing Gyre — Ambient AI OS${RESET}\n"
  printf "${DIM}  https://getgyre.com${RESET}\n"
  printf "\n"

  check_deps

  OS="$(detect_os)"
  ARCH="$(detect_arch)"
  BINARY_NAME="gyre-${ARCH}-${OS}"
  DOWNLOAD_URL="${RELEASES_BASE}/${GYRE_VERSION}/${BINARY_NAME}"

  info "Platform: ${ARCH}-${OS}"
  info "Version:  ${GYRE_VERSION}"
  info "Source:   ${DOWNLOAD_URL}"

  step "Downloading..."

  # Create temp file
  TMP_DIR="$(mktemp -d)"
  TMP_BIN="${TMP_DIR}/gyre"
  trap 'rm -rf "$TMP_DIR"' EXIT

  # Download
  if ! download_binary "$DOWNLOAD_URL" "$TMP_BIN"; then
    warn "Binary not yet available at: ${DOWNLOAD_URL}"
    warn "Gyre is in early access — releases will be available soon."
    warn "Star the repo and watch for release notifications:"
    warn "  https://github.com/sac916/getgyre.com"
    error "Download failed. Please try again when releases are live."
  fi

  # Verify the file was downloaded and is non-empty
  if [ ! -s "$TMP_BIN" ]; then
    error "Downloaded file is empty. The release may not be available yet."
  fi

  # Make executable
  chmod +x "$TMP_BIN"

  step "Installing to ${INSTALL_DIR}/gyre..."

  # Try to install without sudo, fall back to sudo
  if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_BIN" "${INSTALL_DIR}/gyre"
  else
    info "Requesting sudo to write to ${INSTALL_DIR}..."
    sudo mv "$TMP_BIN" "${INSTALL_DIR}/gyre"
  fi

  # Verify install
  if ! command -v gyre > /dev/null 2>&1; then
    warn "gyre was installed to ${INSTALL_DIR}/gyre but may not be in your PATH."
    warn "Add ${INSTALL_DIR} to your PATH or run: ${INSTALL_DIR}/gyre init"
  fi

  step "Done!"
  printf "\n"
  ok "Gyre installed successfully."
  printf "\n"
  printf "  ${BOLD}Next steps:${RESET}\n"
  printf "  ${CYAN}gyre init${RESET}   — set up your first agent\n"
  printf "  ${CYAN}gyre serve${RESET}  — start your tribe\n"
  printf "  ${CYAN}gyre --help${RESET} — see all commands\n"
  printf "\n"
  printf "  ${DIM}Docs: https://getgyre.com/docs${RESET}\n"
  printf "\n"
}

main "$@"
