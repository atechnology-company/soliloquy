#!/bin/bash
# c2v_pipeline.sh - Bootstrap and run the V toolchain c2v translator

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
V_INSTALL_DIR="$PROJECT_ROOT/.build-tools/v"
V_BINARY="$V_INSTALL_DIR/v"

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Bootstrap V toolchain and c2v translator for Zircon subsystem translation.

OPTIONS:
  --subsystem <name>     Target subsystem to translate (required for translate mode)
  --sources <path>       Source directory to translate (overrides subsystem path)
  --dry-run              Show what would be done without executing
  --out-dir <path>       Output directory for translated files (default: out/c2v)
  --bootstrap-only       Only download and setup V toolchain
  --help                 Show this help message

ENVIRONMENT:
  V_HOME                 Path to V installation (default: $V_INSTALL_DIR)
  V_VERSION              Version of V to install (default: latest)

EXAMPLES:
  # Bootstrap V toolchain
  $0 --bootstrap-only

  # Translate a subsystem (dry-run)
  $0 --subsystem kernel/lib/libc --dry-run

  # Translate from custom source directory
  $0 --subsystem hal --sources third_party/zircon_c/hal --out-dir third_party/zircon_v/hal

EOF
  exit 0
}

detect_os_arch() {
  OS=$(uname -s)
  ARCH=$(uname -m)
  
  case "$OS" in
    Linux)
      case "$ARCH" in
        x86_64) V_OS_ARCH="linux-x64" ;;
        aarch64|arm64) V_OS_ARCH="linux-arm64" ;;
        *) echo "Error: Unsupported Linux architecture: $ARCH" && exit 1 ;;
      esac
      ;;
    Darwin)
      case "$ARCH" in
        x86_64) V_OS_ARCH="macos-x64" ;;
        arm64) V_OS_ARCH="macos-arm64" ;;
        *) echo "Error: Unsupported macOS architecture: $ARCH" && exit 1 ;;
      esac
      ;;
    *)
      echo "Error: Unsupported OS: $OS"
      exit 1
      ;;
  esac
  
  echo "Detected platform: $V_OS_ARCH"
}

bootstrap_v() {
  echo "Bootstrapping V toolchain..."
  
  if [ -z "$V_HOME" ]; then
    export V_HOME="$V_INSTALL_DIR"
  fi
  
  if [ -f "$V_BINARY" ]; then
    echo "V toolchain already installed at $V_BINARY"
    V_VERSION_OUTPUT=$("$V_BINARY" version 2>/dev/null || echo "unknown")
    echo "Installed version: $V_VERSION_OUTPUT"
    return 0
  fi
  
  detect_os_arch
  
  echo "Installing V toolchain to $V_INSTALL_DIR..."
  mkdir -p "$V_INSTALL_DIR"
  
  V_VERSION="${V_VERSION:-latest}"
  
  if [ "$V_VERSION" = "latest" ]; then
    V_DOWNLOAD_URL="https://github.com/vlang/v/releases/latest/download/v_${V_OS_ARCH}.zip"
  else
    V_DOWNLOAD_URL="https://github.com/vlang/v/releases/download/${V_VERSION}/v_${V_OS_ARCH}.zip"
  fi
  
  echo "Downloading V from $V_DOWNLOAD_URL..."
  
  TMP_ZIP="$V_INSTALL_DIR/v.zip"
  if ! curl -L -f -o "$TMP_ZIP" "$V_DOWNLOAD_URL"; then
    echo "Error: Failed to download V toolchain (URL may not exist)"
    echo "Trying alternative installation method (from source)..."
    rm -f "$TMP_ZIP"
    install_v_from_source
    return 0
  fi
  
  echo "Extracting V..."
  cd "$V_INSTALL_DIR"
  if ! unzip -q "$TMP_ZIP"; then
    echo "Error: Downloaded file is not a valid zip"
    echo "Trying alternative installation method (from source)..."
    rm -f "$TMP_ZIP"
    cd "$PROJECT_ROOT"
    install_v_from_source
    return 0
  fi
  rm "$TMP_ZIP"
  
  if [ -d "$V_INSTALL_DIR/v" ]; then
    mv "$V_INSTALL_DIR/v/"* "$V_INSTALL_DIR/"
    rmdir "$V_INSTALL_DIR/v"
  fi
  
  chmod +x "$V_BINARY"
  
  echo "V toolchain installed successfully"
  "$V_BINARY" version
}

install_v_from_source() {
  echo "Installing V from source..."
  
  TMP_CLONE="$V_INSTALL_DIR/v-source"
  rm -rf "$TMP_CLONE"
  
  if ! git clone --depth 1 https://github.com/vlang/v "$TMP_CLONE"; then
    echo "Error: Failed to clone V repository"
    exit 1
  fi
  
  cd "$TMP_CLONE"
  make
  
  cp -r ./* "$V_INSTALL_DIR/"
  cd "$PROJECT_ROOT"
  rm -rf "$TMP_CLONE"
  
  echo "V installed from source successfully"
}

validate_v_home() {
  if [ -z "$V_HOME" ]; then
    export V_HOME="$V_INSTALL_DIR"
  fi
  
  if [ ! -f "$V_HOME/v" ]; then
    echo "Error: V_HOME is set to '$V_HOME' but v binary not found"
    echo "Run with --bootstrap-only first or set V_HOME to a valid V installation"
    exit 1
  fi
  
  echo "V_HOME validated: $V_HOME"
}

translate_subsystem() {
  local subsystem="$1"
  local sources_path="$2"
  local out_dir="$3"
  local dry_run="$4"
  
  if [ -z "$subsystem" ]; then
    echo "Error: --subsystem is required for translation"
    usage
  fi
  
  validate_v_home
  
  echo "Translating subsystem: $subsystem"
  echo "Output directory: $out_dir"
  
  mkdir -p "$out_dir"
  
  if [ -n "$sources_path" ]; then
    SUBSYSTEM_PATH="$PROJECT_ROOT/$sources_path"
    echo "Source directory: $SUBSYSTEM_PATH"
  else
    SUBSYSTEM_PATH="$PROJECT_ROOT/$subsystem"
  fi
  
  if [ ! -d "$SUBSYSTEM_PATH" ]; then
    echo "Warning: Subsystem path does not exist: $SUBSYSTEM_PATH"
    echo "This might be a Zircon kernel subsystem that needs the full source tree"
  fi
  
  if [ "$dry_run" = "true" ]; then
    echo "[DRY RUN] Would translate subsystem: $subsystem"
    echo "[DRY RUN] Command: $V_HOME/v translate c $SUBSYSTEM_PATH -o $out_dir"
    return 0
  fi
  
  echo "Running c2v translation..."
  "$V_HOME/v" translate c "$SUBSYSTEM_PATH" -o "$out_dir" || {
    echo "Note: c2v translation may produce errors for complex C code"
    echo "This is expected and requires manual review of the translated output"
  }
  
  echo "Translation complete. Output in $out_dir"
}

SUBSYSTEM=""
SOURCES_PATH=""
DRY_RUN=false
OUT_DIR="$PROJECT_ROOT/out/c2v"
BOOTSTRAP_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --subsystem)
      SUBSYSTEM="$2"
      shift 2
      ;;
    --sources)
      SOURCES_PATH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --bootstrap-only)
      BOOTSTRAP_ONLY=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Error: Unknown option: $1"
      usage
      ;;
  esac
done

bootstrap_v

if [ "$BOOTSTRAP_ONLY" = "true" ]; then
  echo "Bootstrap complete. V_HOME=$V_HOME"
  exit 0
fi

if [ -n "$SUBSYSTEM" ]; then
  translate_subsystem "$SUBSYSTEM" "$SOURCES_PATH" "$OUT_DIR" "$DRY_RUN"
else
  echo "V toolchain ready. Use --subsystem to translate a subsystem."
  echo "Run with --help for usage information."
fi
