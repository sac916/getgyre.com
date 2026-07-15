#!/usr/bin/env sh
# Gyre installer
# Usage: curl -fsSL https://getgyre.com/install | sh
# More info: https://getgyre.com/install

set -e

GYRE_VERSION="${GYRE_VERSION:-latest}"
RELEASES_BASE="https://github.com/SargassoLLC/gyre/releases"
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

# ─── Download file (returns 0 on success, 1 on 404/error) ─────────────────────
try_download() {
  local url="$1"
  local dest="$2"

  if [ "$DOWNLOADER" = "curl" ]; then
    curl -fsSL --progress-bar -L "$url" -o "$dest" 2>/dev/null
  else
    wget -q --show-progress "$url" -O "$dest" 2>/dev/null
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
  TARGET="${ARCH}-${OS}"

  # cargo-dist archives: unversioned (new) and versioned (legacy) names
  # Try unversioned first: gyre-<target>.tar.gz (cargo-dist default, no version in filename)
  # Fall back to versioned: gyre-<version>-<target>.tar.gz (older releases)
  ARCHIVE_UNVERSIONED="gyre-${TARGET}.tar.gz"
  if [ "$GYRE_VERSION" = "latest" ]; then
    URL_UNVERSIONED="${RELEASES_BASE}/latest/download/${ARCHIVE_UNVERSIONED}"
  else
    ARCHIVE_VERSIONED="gyre-${GYRE_VERSION}-${TARGET}.tar.gz"
    URL_VERSIONED="${RELEASES_BASE}/download/${GYRE_VERSION}/${ARCHIVE_VERSIONED}"
    URL_UNVERSIONED="${RELEASES_BASE}/download/${GYRE_VERSION}/${ARCHIVE_UNVERSIONED}"
  fi

  info "Platform: ${TARGET}"
  info "Version:  ${GYRE_VERSION}"
  info "Source:   ${URL_UNVERSIONED}"

  step "Downloading..."

  # Create temp directory
  TMP_DIR="$(mktemp -d)"
  TMP_ARCHIVE="${TMP_DIR}/gyre.tar.gz"
  TMP_BIN="${TMP_DIR}/gyre"
  trap 'rm -rf "$TMP_DIR"' EXIT

  # Try unversioned archive name first (cargo-dist / current releases)
  DOWNLOAD_OK=0
  if try_download "$URL_UNVERSIONED" "$TMP_ARCHIVE" && [ -s "$TMP_ARCHIVE" ]; then
    DOWNLOAD_OK=1
    info "Downloaded ${ARCHIVE_UNVERSIONED}"
  elif [ "$GYRE_VERSION" != "latest" ]; then
    # Fall back to versioned archive name (legacy releases)
    info "Trying versioned archive name..."
    if try_download "$URL_VERSIONED" "$TMP_ARCHIVE" && [ -s "$TMP_ARCHIVE" ]; then
      DOWNLOAD_OK=1
      info "Downloaded ${ARCHIVE_VERSIONED}"
    fi
  fi

  if [ "$DOWNLOAD_OK" = "0" ]; then
    warn "Archive not yet available for platform: ${TARGET}"
    warn "Gyre is in early access — releases will be available soon."
    warn "Star the repo and watch for release notifications:"
    warn "  https://github.com/SargassoLLC/gyre"
    error "Download failed. Please try again when releases are live."
  fi

  # Extract binary from the archive
  if ! tar -xzf "$TMP_ARCHIVE" -C "$TMP_DIR" --strip-components=1 gyre 2>/dev/null; then
    # Some archives may not have a subdirectory; try without strip
    tar -xzf "$TMP_ARCHIVE" -C "$TMP_DIR" 2>/dev/null || true
    # Find the extracted binary
    FOUND_BIN="$(find "$TMP_DIR" -maxdepth 2 -name "gyre" -type f | head -1)"
    if [ -z "$FOUND_BIN" ]; then
      error "Could not find gyre binary inside the downloaded archive."
    fi
    cp "$FOUND_BIN" "$TMP_BIN"
  fi

  # Verify the binary is non-empty
  if [ ! -s "$TMP_BIN" ]; then
    error "Extracted binary is empty. The release may be malformed."
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
    warn "Add ${INSTALL_DIR} to your PATH or run: ${INSTALL_DIR}/gyre setup"
  fi

  step "Done!"
  printf "\n"
  ok "Gyre installed successfully."
  printf "\n"
  printf "  ${BOLD}Next steps:${RESET}\n"
  printf "  ${CYAN}gyre setup${RESET}  — set up your first agent\n"
  printf "  ${CYAN}gyre run${RESET}    — start your tribe\n"
  printf "  ${CYAN}gyre --help${RESET} — see all commands\n"
  printf "\n"
  printf "  ${DIM}Docs: https://getgyre.com/docs${RESET}\n"
  printf "\n"
}

main "$@"
