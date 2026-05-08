# =============================================================================
# Control D JFK Profile - Installation Script for Windows
# =============================================================================
# Description: Installs ctrld service and configures NY-GCR (JFK) profile
# Usage: .\install-windows.ps1 -ResolverId "YOUR_RESOLVER_ID"
# Requirements: Run as Administrator
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ResolverId = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerifyOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Uninstall
)

# =============================================================================
# Configuration
# =============================================================================
$ScriptVersion = "3.0"
$LogFile = "$env:TEMP\controld-install.log"
$ConfigDir = "$env:ProgramData\ControlD"
$ConfigFile = "$ConfigDir\ctrld.toml"

# =============================================================================
# Helper Functions
# =============================================================================

function Write-Banner {
    Write-Host @"
  ____            _             _   ____  _
 / ___|___  _ __ | |_ _ __ ___ | |_/ ___|| |_ ___  _ __
| |   / _ \| '_ \| __| '__/ _ \| __\___ \| __/ _ \| '__|
| |__| (_) | | | | |_| | | (_) | |_ ___) | || (_) | |
 \____\___/|_| |_|\__|_|  \___/ \__|____/ \__\___/|_|
"@ -ForegroundColor Cyan
    Write-Host "NY-GCR Profile Installer v$ScriptVersion (JFK Cloaking)" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host ""
}

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator!"
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }
}

function Install-Ctrld {
    Write-Info "Installing Control D (ctrld)..."
    
    if (Get-Command ctrld -ErrorAction SilentlyContinue) {
        Write-Success "ctrld already installed"
        return
    }
    
    try {
        $InstallerUrl = "https://api.controld.com/dl/ps1"
        $InstallerPath = "$env:TEMP\ctrld_install.ps1"
        
        Write-Info "Downloading installer..."
        (Invoke-WebRequest -Uri $InstallerUrl -UseBasicParsing).Content | Set-Content $InstallerPath
        
        if ($ResolverId) {
            Write-Info "Installing with Resolver ID..."
            & $InstallerPath $ResolverId "forced"
        } else {
            Write-Warn "No ResolverId provided, installing without config..."
            & $InstallerPath
        }
        
        Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
        Write-Success "ctrld installed successfully"
    } catch {
        Write-Error "Failed to install ctrld: $_"
        exit 1
    }
}

function Install-Service {
    Write-Info "Configuring Windows Service..."
    
    # Create config directory
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    
    # Write configuration
    $ConfigContent = @"
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
  endpoint = "https://dns.controld.com/$ResolverId"
  timeout = 5000

[service]
  log_level = "info"
"@
    
    $ConfigContent | Set-Content $ConfigFile -Encoding UTF8
    Write-Success "Configuration written to $ConfigFile"
    
    # Start service
    Write-Info "Starting ctrld service..."
    Start-Process ctrld -ArgumentList "start","--config","`"$ConfigFile`"" -NoNewWindow -Wait
    
    Start-Sleep -Seconds 3
    
    $service = Get-Process ctrld -ErrorAction SilentlyContinue
    if ($service) {
        Write-Success "ctrld service is running (PID: $($service.Id))"
    } else {
        Write-Warn "Service status unclear, checking..."
        ctrld status
    }
}

function Uninstall-Ctrld {
    Write-Info "Uninstalling Control D..."
    
    # Stop service
    Stop-Process -Name ctrld -Force -ErrorAction SilentlyContinue
    
    # Remove from startup
    $StartupKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty -Path $StartupKey -Name "ControlD" -ErrorAction SilentlyContinue
    
    Write-Success "Control D removed (binary kept for safety)"
}

function Test-Installation {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host "DNS Resolution Test:" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    
    try {
        $result = Resolve-DnsName -Name "whoami.controld.com" -Server "127.0.0.1" -ErrorAction Stop
        Write-Success "DNS resolution working"
        Write-Host "  Response: $($result[0].IPAddress)" -ForegroundColor Gray
    } catch {
        Write-Warn "DNS test failed (may need time to initialize)"
    }
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host "Control D Status Check:" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    
    try {
        ctrld status
    } catch {
        Write-Warn "Could not get ctrld status"
    }
    
    Write-Host ""
    Write-Host "Verify full status at: https://controld.com/status" -ForegroundColor Cyan
}

function Show-PostInstall {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host "POST-INSTALLATION NOTES" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "1. Verify status:     https://controld.com/status"
    Write-Host "2. Check service:     Get-Process ctrld"
    Write-Host "3. Restart service:   Restart-Service ctrld (or ctrld restart)"
    Write-Host "4. Edit config:       $ConfigFile"
    Write-Host "5. View logs:         Get-Content `$env:TEMP\ctrld.log -Tail 50"
    Write-Host ""
    Write-Host "JFK Profile Active Features:" -ForegroundColor Cyan
    Write-Host "  - All traffic redirects through JFK (NYC)" -ForegroundColor Gray
    Write-Host "  - 60+ services proxied (Google, Meta, AI, Banking)" -ForegroundColor Gray
    Write-Host "  - Geo-rule: non-US destinations auto-redirect" -ForegroundColor Gray
    Write-Host "  - Filters: Malware, Ads, Typo-squatting, IoT" -ForegroundColor Gray
    Write-Host "  - Bypassed: VPN services, some analytics" -ForegroundColor Gray
    Write-Host ""
    Write-Host "IMPORTANT: Configure Windows to use 127.0.0.1 as DNS:" -ForegroundColor Yellow
    Write-Host "  Settings > Network > Adapter > IPv4 DNS: 127.0.0.1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Installation complete!" -ForegroundColor Green
}

# =============================================================================
# Main
# =============================================================================

Write-Banner

if ($Uninstall) {
    Test-Admin
    Uninstall-Ctrld
    exit 0
}

if ($VerifyOnly) {
    Test-Installation
    exit 0
}

Test-Admin

if ([string]::IsNullOrEmpty($ResolverId)) {
    Write-Error "ResolverId is required!"
    Write-Host ""
    Write-Host "Usage: .\install-windows.ps1 -ResolverId 'YOUR_RESOLVER_ID'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Get your Resolver ID from:" -ForegroundColor Cyan
    Write-Host "  1. Go to https://controld.com/dashboard" -ForegroundColor Gray
    Write-Host "  2. Create or select an Endpoint" -ForegroundColor Gray
    Write-Host "  3. Copy the Resolver ID from endpoint settings" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Install-Ctrld
Install-Service
Test-Installation
Show-PostInstall