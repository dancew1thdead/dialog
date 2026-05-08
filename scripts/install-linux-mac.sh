#!/bin/bash
# =============================================================================
# Control D JFK Profile - Installation Script for Linux / macOS
# =============================================================================
# Description: Installs ctrld daemon and configures NY-GCR (JFK) profile
# Usage: ./install-linux-mac.sh <RESOLVER_ID>
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOLVER_ID="${1:-}"
CTRDL_BIN="/usr/bin/ctrld"
LOG_FILE="/var/log/controld-install.log"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${RED}[ERROR]${NC} $1"
}

banner() {
    echo -e "${BLUE}"
    echo "  ____            _             _   ____  _"
    echo " / ___|___  _ __ | |_ _ __ ___ | |_/ ___|| |_ ___  _ __"
    echo "| |   / _ \| '_ \| __| '__/ _ \| __\\___ \| __/ _ \| '_ \\"
    echo "| |__| (_) | | | | |_| | | (_) | |_ ___) | || (_) | |"
    echo " \\____\\___/|_| |_|\\__|_|  \\___/ \\__|____/ \\__\\___/|_|"
    echo ""
    echo -e "${NC}NY-GCR Profile Installer (JFK Cloaking)${NC}"
    echo "========================================="
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &>/dev/null; then
            OS="debian"
        elif command -v yum &>/dev/null; then
            OS="rhel"
        elif command -v pacman &>/dev/null; then
            OS="arch"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        log_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    log_info "Detected OS: $OS"
}

install_deps() {
    log_info "Installing dependencies..."
    case $OS in
        debian)
            apt-get update -qq
            apt-get install -y -qq curl ca-certificates systemd
            ;;
        rhel)
            yum install -y -q curl ca-certificates systemd
            ;;
        arch)
            pacman -Sy --noconfirm --quiet curl ca-certificates systemd
            ;;
        macos)
            if ! command -v brew &>/dev/null; then
                log_warn "Homebrew not found. Some features may be limited."
            fi
            ;;
    esac
    log_success "Dependencies installed"
}

install_ctrld() {
    log_info "Installing Control D (ctrld)..."
    
    # Official installer
    if ! command -v ctrld &>/dev/null; then
        log_info "Downloading and installing ctrld..."
        curl -sL https://api.controld.com/dl -o /tmp/ctrld_install.sh
        chmod +x /tmp/ctrld_install.sh
        
        if [[ -n "$RESOLVER_ID" ]]; then
            sh /tmp/ctrld_install.sh "$RESOLVER_ID" forced
        else
            log_warn "No RESOLVER_ID provided. Installing without configuration..."
            sh /tmp/ctrld_install.sh
        fi
        
        rm -f /tmp/ctrld_install.sh
    else
        log_info "ctrld already installed, skipping..."
    fi
    
    log_success "ctrld installed"
}

configure_profile() {
    log_info "Configuring NY-GCR profile..."
    
    # Create configuration directory
    mkdir -p /etc/controld
    
    # Write configuration
    cat > /etc/controld/ctrld.toml << 'EOF'
[listener]
  [listener.0]
    ip = "127.0.0.1"
    port = 53

[listener.0.policy]
  name = "NY-GCR Policy"
  networks = ["0.0.0.0/0"]

[network.0]
  name = "All Networks"
  cidrs = ["0.0.0.0/0"]

[upstream.0]
  type = "doh"
  endpoint = "https://dns.controld.com/RESOLVER_ID"
  timeout = 5000

[service]
  log_level = "info"
  log_path = "/var/log/controld.log"
EOF
    
    if [[ -n "$RESOLVER_ID" ]]; then
        sed -i.bak "s/RESOLVER_ID/$RESOLVER_ID/g" /etc/controld/ctrld.toml
        rm -f /etc/controld/ctrld.toml.bak
    fi
    
    log_success "Profile configured"
}

start_service() {
    log_info "Starting ctrld service..."
    
    if command -v systemctl &>/dev/null; then
        systemctl enable ctrld 2>/dev/null || true
        systemctl restart ctrld 2>/dev/null || ctrld start --config /etc/controld/ctrld.toml
    else
        ctrld start --daemon --config /etc/controld/ctrld.toml
    fi
    
    sleep 2
    
    if pgrep -x "ctrld" > /dev/null || systemctl is-active ctrld &>/dev/null; then
        log_success "ctrld service is running"
    else
        log_warn "Service status unclear, check manually"
    fi
}

verify_installation() {
    log_info "Verifying installation..."
    
    echo ""
    echo "=========================================="
    echo "DNS Resolution Test:"
    echo "=========================================="
    
    # Test DNS resolution
    if command -v dig &>/dev/null; then
        DNS_RESULT=$(dig +short whoami.controld.com @127.0.0.1 2>/dev/null || echo "FAILED")
        if [[ "$DNS_RESULT" != "FAILED" && -n "$DNS_RESULT" ]]; then
            log_success "DNS resolution working"
            echo "  DNS Response: $DNS_RESULT"
        else
            log_warn "DNS resolution test inconclusive"
        fi
    elif command -v nslookup &>/dev/null; then
        nslookup whoami.controld.com 127.0.0.1 >/dev/null 2>&1 && \
            log_success "DNS resolution working" || log_warn "DNS test failed"
    else
        log_warn "Neither dig nor nslookup available for testing"
    fi
    
    echo ""
    echo "=========================================="
    echo "IP Geolocation Check:"
    echo "=========================================="
    
    if command -v curl &>/dev/null; then
        curl -s --max-time 10 https://ipinfo.io 2>/dev/null | head -20 || \
            log_warn "Cannot reach ipinfo.io (this is normal)"
    fi
    
    echo ""
    log_info "Verify full status at: https://controld.com/status"
}

show_post_install() {
    echo ""
    echo "=========================================="
    echo "POST-INSTALLATION NOTES"
    echo "=========================================="
    echo ""
    echo "1. Verify status:     https://controld.com/status"
    echo "2. Check logs:        journalctl -u ctrld -f"
    echo "3. Restart service:   systemctl restart ctrld"
    echo "4. Edit config:       /etc/controld/ctrld.toml"
    echo ""
    echo "JFK Profile Active Features:"
    echo "  - All traffic redirects through JFK (NYC)"
    echo "  - 60+ services proxied (Google, Meta, AI, Banking)"
    echo "  - Geo-rule: non-US destinations auto-redirect"
    echo "  - Filters: Malware, Ads, Typo-squatting, IoT"
    echo "  - Bypassed: VPN services, some analytics"
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
}

# =============================================================================
# Main
# =============================================================================

main() {
    banner
    
    if [[ -z "$RESOLVER_ID" ]]; then
        echo "Usage: $0 <RESOLVER_ID>"
        echo ""
        echo "Get your Resolver ID from:"
        echo "  1. Go to https://controld.com/dashboard"
        echo "  2. Create or select an Endpoint"
        echo "  3. Copy the Resolver ID from endpoint settings"
        echo ""
        exit 1
    fi
    
    check_root
    detect_os
    install_deps
    install_ctrld
    configure_profile
    start_service
    verify_installation
    show_post_install
}

main "$@"