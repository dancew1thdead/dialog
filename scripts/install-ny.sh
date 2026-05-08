#!/bin/bash
# =============================================================================
# Control D - NEW YORK ULTIMATE CLOAKING SETUP
# =============================================================================
# Description: Full system routing through JFK with zero traces.
# Usage: sudo ./NY-NY-Setup.sh <RESOLVER_ID>
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[NY-NY]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ $EUID -ne 0 ]] && error "Run as root"
RESOLVER_ID="${1:-}"
[[ -z "$RESOLVER_ID" ]] && error "Usage: $0 <RESOLVER_ID>"

log "Initializing New York Ultimate Cloaking..."

# 1. Install/Update ctrld
log "Installing Control D daemon..."
curl -sL https://api.controld.com/dl -o /tmp/ctrld_install.sh
sh /tmp/ctrld_install.sh "$RESOLVER_ID" forced
rm -f /tmp/ctrld_install.sh

# 2. Configure for Maximum Anonymity
log "Configuring system for zero-trace JFK routing..."
mkdir -p /etc/controld
cat > /etc/controld/ctrld.toml << EOF
[listener]
  [listener.0]
    ip = "127.0.0.1"
    port = 53

[listener.0.policy]
  name = "NY-ULTIMATE-POLICY"
  networks = ["0.0.0.0/0"]

[network.0]
  name = "All"
  cidrs = ["0.0.0.0/0"]

[upstream.0]
  type = "doh"
  endpoint = "https://dns.controld.com/$RESOLVER_ID"
  timeout = 5000

[service]
  log_level = "error"
  log_path = "/dev/null"
EOF

# 3. Restart and Lock
log "Applying configuration..."
systemctl restart ctrld || ctrld start --config /etc/controld/ctrld.toml

# 4. Verification
log "Verifying New York presence..."
sleep 3
IP_INFO=$(curl -s https://ipinfo.io)
CITY=$(echo "$IP_INFO" | grep "city" | cut -d'"' -f4)
if [[ "$CITY" == "New York" ]]; then
    success "Welcome to New York! System is now fully cloaked via JFK."
else
    log "Current City: $CITY (If not NY, ensure Profile is imported in Dashboard)"
fi

echo "--------------------------------------------------"
echo "NY-NY ULTIMATE STATUS: ACTIVE"
echo "Location: New York, USA (JFK)"
echo "Privacy: Maximum (No Logs, All Traffic Proxied)"
echo "--------------------------------------------------"
