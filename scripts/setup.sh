#!/usr/bin/env bash
#
# Android Development Environment Setup Script
# Supports: aarch64/arm64 Linux (native build-tools)
# Author: miahsobuj
#

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly ANDROID_SDK_VERSION="34"
readonly GRADLE_VERSION="8.7"
readonly BUILD_TOOLS_VERSION="34.0.0"
readonly BUILD_TOOLS_VERSION_NEW="36.1.0"

# URLs for aarch64 native tools
readonly LZHIYONG_SDK_URL="https://github.com/lzhiyong/android-sdk-tools/releases/download"
readonly HOMUHOMU_SDK_URL="https://github.com/HomuHomu833/android-sdk-custom/releases/download"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat << EOF
Android Development Environment Setup v${SCRIPT_VERSION}

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -d, --dir DIR           Installation directory (default: ~/android-dev)
    -y, --yes               Skip confirmation prompts
    -c, --clean             Clean existing installation
    -v, --verify            Verify installation only

EXAMPLES:
    $0                      # Interactive setup to ~/android-dev
    $0 -d /opt/android       # Custom installation directory
    $0 -c -y                # Clean and reinstall
    $0 -v                   # Verify current installation

EOF
    exit 0
}

cleanup() {
    log_info "Cleaning up..."
    if [[ -d "${INSTALL_DIR}" ]]; then
        rm -rf "${INSTALL_DIR}"
    fi
    if [[ -f "${HOME}/.bashrc.android" ]]; then
        rm -f "${HOME}/.bashrc.android"
    fi
    log_success "Cleanup complete"
}

check_architecture() {
    local arch
    arch=$(uname -m)
    if [[ "$arch" != "aarch64" && "$arch" != "arm64" ]]; then
        log_warn "This script is optimized for aarch64/arm64"
        log_warn "Current architecture: $arch"
    fi
    log_info "Architecture: $arch"
}

check_dependencies() {
    log_info "Checking dependencies..."

    local missing_deps=()

    command -v java >/dev/null 2>&1 || missing_deps+=("java")
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v unzip >/dev/null 2>&1 || missing_deps+=("unzip")
    command -v xz >/dev/null 2>&1 || missing_deps+=("xz")

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install with: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi

    local java_version
    java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    log_info "Java version: $java_version"

    local java_major
    java_major=$(echo "$java_version" | cut -d'.' -f1)
    if [[ "$java_major" -lt 17 ]]; then
        log_error "Java 17+ is required. Found: $java_version"
        log_info "Install with: sudo apt-get install openjdk-17-jdk"
        exit 1
    fi

    log_success "All dependencies satisfied"
}

download_file() {
    local url="$1"
    local output="$2"
    local description="$3"

    log_info "Downloading $description..."
    if curl -L --progress-bar -o "$output" "$url"; then
        log_success "Downloaded $description"
    else
        log_error "Failed to download $description"
        return 1
    fi
}

install_java() {
    if command -v java >/dev/null 2>&1; then
        log_info "Java already installed: $(java -version 2>&1 | head -1)"
        return 0
    fi

    log_info "Installing OpenJDK 17..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y openjdk-17-jdk
        log_success "OpenJDK 17 installed"
    else
        log_error "Cannot install Java automatically. Please install JDK 17 manually."
        exit 1
    fi
}

install_gradle() {
    local gradle_dir="${INSTALL_DIR}/gradle"
    local gradle_bin="${gradle_dir}/gradle-${GRADLE_VERSION}/bin/gradle"

    if [[ -x "$gradle_bin" ]]; then
        log_info "Gradle already installed: $gradle_bin"
        return 0
    fi

    log_info "Installing Gradle ${GRADLE_VERSION}..."

    mkdir -p "$gradle_dir"
    cd "$gradle_dir"

    download_file \
        "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
        "gradle.zip" \
        "Gradle ${GRADLE_VERSION}"

    unzip -q gradle.zip
    rm gradle.zip
    mv "gradle-${GRADLE_VERSION}" "gradle-${GRADLE_VERSION}"
    ln -sf "gradle-${GRADLE_VERSION}/bin/gradle" "${INSTALL_DIR}/gradle"

    log_success "Gradle installed: $gradle_bin"
}

install_android_sdk() {
    local sdk_dir="${INSTALL_DIR}/sdk"

    if [[ -d "$sdk_dir/build-tools/${BUILD_TOOLS_VERSION}" ]]; then
        log_info "Android SDK already installed"
        return 0
    fi

    log_info "Installing Android SDK..."

    mkdir -p "$sdk_dir"

    # Download lzhiyong's aarch64 SDK (build-tools 34.0.0 + platform-tools)
    download_file \
        "${LZHIYONG_SDK_URL}/34.0.3/android-sdk-tools-static-aarch64.zip" \
        "${sdk_dir}/aarch64-tools.zip" \
        "lzhiyong's aarch64 SDK tools"

    cd "$sdk_dir"
    unzip -o -q aarch64-tools.zip
    rm -f aarch64-tools.zip

    # Setup build-tools directory structure
    mkdir -p "build-tools/${BUILD_TOOLS_VERSION}"
    mv build-tools/aapt build-tools/aapt2 build-tools/aidl build-tools/dexdump \
       build-tools/split-select build-tools/zipalign "build-tools/${BUILD_TOOLS_VERSION}/" 2>/dev/null || true

    log_info "Downloading HomuHomu's aarch64 SDK (build-tools 36.1.0)..."
    download_file \
        "${HOMUHOMU_SDK_URL}/36.0.0/android-sdk-aarch64-linux-musl.tar.xz" \
        "${sdk_dir}/homuhomu-sdk.tar.xz" \
        "HomuHomu's aarch64 SDK"

    tar -xf homuhomu-sdk.tar.xz
    rm -f homuhomu-sdk.tar.xz

    if [[ -d "android-sdk/build-tools/36.1.0" ]]; then
        mv android-sdk/build-tools/36.1.0 build-tools/
        rm -rf android-sdk
    fi

    log_success "Android SDK installed"
}

install_android_cmdline_tools() {
    local cmdline_dir="${INSTALL_DIR}/sdk/cmdline-tools"
    local latest_dir="${cmdline_dir}/latest"

    if [[ -d "$latest_dir/bin" ]]; then
        log_info "Android cmdline-tools already installed"
        return 0
    fi

    log_info "Installing Android cmdline-tools..."

    mkdir -p "$cmdline_dir"
    cd "$cmdline_dir"

    download_file \
        "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
        "cmdline-tools.zip" \
        "Android cmdline-tools"

    unzip -q cmdline-tools.zip
    rm cmdline-tools.zip
    mv cmdline-tools latest

    # Accept licenses
    yes | "${latest_dir}/bin/sdkmanager" --licenses >/dev/null 2>&1 || true

    # Install required SDK components
    log_info "Installing SDK components (platform-tools, platform API ${ANDROID_SDK_VERSION}, build-tools)..."
    "${latest_dir}/bin/sdkmanager" \
        "platform-tools" \
        "platforms;android-${ANDROID_SDK_VERSION}" \
        "build-tools;${BUILD_TOOLS_VERSION}" \
        --sdk_root="${INSTALL_DIR}/sdk"

    log_success "Android cmdline-tools installed"
}

setup_environment() {
    log_info "Setting up environment variables..."

    local env_file="${HOME}/.bashrc.android"

    cat > "$env_file" << EOF
# Android Development Environment
# Generated by android-setup.sh

export ANDROID_HOME="${INSTALL_DIR}/sdk"
export ANDROID_SDK_ROOT="${INSTALL_DIR}/sdk"
export JAVA_HOME="\$(dirname "\$(dirname "\$(readlink -f "\$(which java)"))")"

# Add SDK tools to PATH
export PATH="\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/platform-tools:\${PATH}"

# Add Gradle to PATH
export PATH="${INSTALL_DIR}/gradle/gradle-${GRADLE_VERSION}/bin:\${PATH}"

# Aliases for common tasks
alias adb-devices='adb devices'
alias adb-logcat='adb logcat'
alias gradle-clean='./gradlew clean'
alias gradle-build='./gradlew assembleDebug'
alias gradle-release='./gradlew assembleRelease'
EOF

    log_success "Environment file created: $env_file"
    log_info "Add to your shell: source $env_file"
}

verify_installation() {
    log_info "Verifying installation..."

    local errors=0

    # Check Java
    if command -v java >/dev/null 2>&1; then
        log_success "Java: $(java -version 2>&1 | head -1)"
    else
        log_error "Java not found"
        ((errors++))
    fi

    # Check Gradle
    local gradle_bin="${INSTALL_DIR}/gradle/gradle-${GRADLE_VERSION}/bin/gradle"
    if [[ -x "$gradle_bin" ]]; then
        log_success "Gradle: $($gradle_bin --version 2>&1 | head -1)"
    else
        log_error "Gradle not found at $gradle_bin"
        ((errors++))
    fi

    # Check Android SDK
    local aapt2="${INSTALL_DIR}/sdk/build-tools/${BUILD_TOOLS_VERSION}/aapt2"
    if [[ -x "$aapt2" ]]; then
        log_success "aapt2: $($aapt2 version 2>&1)"
    else
        log_error "aapt2 not found at $aapt2"
        ((errors++))
    fi

    # Check SDK manager
    local sdkmanager="${INSTALL_DIR}/sdk/cmdline-tools/latest/bin/sdkmanager"
    if [[ -x "$sdkmanager" ]]; then
        log_success "sdkmanager: installed"
    else
        log_error "sdkmanager not found at $sdkmanager"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Installation verified successfully!"
        return 0
    else
        log_error "Verification failed with $errors error(s)"
        return 1
    fi
}

main() {
    local install_dir="${HOME}/android-dev"
    local clean_mode=false
    local verify_only=false
    local skip_confirmation=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage ;;
            -d|--dir) install_dir="$2"; shift 2 ;;
            -y|--yes) skip_confirmation=true; shift ;;
            -c|--clean) clean_mode=true; shift ;;
            -v|--verify) verify_only=true; shift ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    readonly INSTALL_DIR="$install_dir"

    echo "============================================"
    echo " Android Development Setup v${SCRIPT_VERSION}"
    echo "============================================"
    echo ""

    if [[ "$verify_only" == true ]]; then
        verify_installation
        exit $?
    fi

    if [[ "$clean_mode" == true ]]; then
        cleanup
        [[ "$skip_confirmation" == true ]] || exit 0
    fi

    check_architecture
    check_dependencies

    if [[ "$skip_confirmation" != true ]]; then
        echo ""
        log_warn "Installation directory: $INSTALL_DIR"
        read -p "Continue? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    install_java
    install_gradle
    install_android_sdk
    install_android_cmdline_tools
    setup_environment

    echo ""
    echo "============================================"
    verify_installation
    echo ""
    log_success "Setup complete!"
    echo ""
    log_info "To use, run: source ${HOME}/.bashrc.android"
    echo "============================================"
}

main "$@"
