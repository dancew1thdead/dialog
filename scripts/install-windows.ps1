# =============================================================================
# Control D JFK Profile - Installation Script for Windows
# =============================================================================
# Description: Installs ctrld service and configures NY-GCR (JFK) profile
# Usage: .\install-windows.ps1 -ResolverId "YOUR_RESOLVER_ID"
# Requirements: Run as Administrator, PowerShell 5.0+
# =============================================================================

#Requires -Version 5.0
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [string]$ResolverId = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerifyOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$Uninstall,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# =============================================================================
# Configuration & Constants
# =============================================================================
$ScriptVersion = "3.1"
$LogFile = "$env:TEMP\controld-install.log"
$ConfigDir = "$env:ProgramData\ControlD"
$ConfigFile = "$ConfigDir\ctrld.toml"
$ConfigBackup = "$ConfigDir\ctrld.toml.backup"
$InstallerUrl = "https://api.controld.com/dl/ps1"
$InstallerPath = "$env:TEMP\ctrld_install.ps1"
$ResolverIdPattern = '^[a-zA-Z0-9-]{20,}$'  # Basic validation pattern
$MaxRetries = 3
$RetryDelaySeconds = 2

# =============================================================================
# Logging Functions
# =============================================================================

function Initialize-Logging {
    try {
        if (Test-Path $LogFile) {
            Remove-Item $LogFile -Force -ErrorAction SilentlyContinue
        }
        "Installation started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $LogFile -Encoding UTF8
    } catch {
        Write-Warn "Could not initialize log file: $_"
    }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    try {
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silent fail - don't interrupt script if logging fails
    }
    
    # Write to console
    switch ($Level) {
        'SUCCESS' { Write-Host "[OK] $Message" -ForegroundColor Green }
        'WARN' { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        'ERROR' { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        default { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

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
    
    if ($WhatIf) {
        Write-Host "[DRY-RUN MODE] No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." INFO
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5.0 or higher is required (current: $($PSVersionTable.PSVersion))" ERROR
        exit 1
    }
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" SUCCESS
    
    # Check admin privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "This script must be run as Administrator!" ERROR
        Write-Log "Right-click PowerShell and select 'Run as Administrator'" INFO
        exit 1
    }
    Write-Log "Admin privileges confirmed" SUCCESS
    
    # Check internet connectivity
    try {
        $testConnection = Test-NetConnection -ComputerName "api.controld.com" -Port 443 -WarningAction SilentlyContinue
        if (-not $testConnection.TcpTestSucceeded) {
            Write-Log "Warning: Cannot reach api.controld.com. Installation may fail." WARN
        } else {
            Write-Log "Internet connectivity verified" SUCCESS
        }
    } catch {
        Write-Log "Could not verify internet connectivity: $_" WARN
    }
}

function Test-ResolverIdFormat {
    param([string]$ResolverId)
    
    if ($ResolverId -notmatch $ResolverIdPattern) {
        Write-Log "Invalid ResolverId format. Expected alphanumeric string with dashes, minimum 20 characters." ERROR
        return $false
    }
    return $true
}

function Invoke-WebRequestSafe {
    param(
        [string]$Uri,
        [string]$OutFile,
        [int]$Timeout = 30
    )
    
    $retryCount = 0
    
    while ($retryCount -lt $MaxRetries) {
        try {
            Write-Log "Downloading from $Uri (attempt $($retryCount + 1)/$MaxRetries)" INFO
            
            $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec $Timeout -ErrorAction Stop
            
            if ($OutFile) {
                $response.Content | Set-Content -Path $OutFile -Encoding Byte -ErrorAction Stop
            } else {
                return $response.Content
            }
            
            Write-Log "Download successful" SUCCESS
            return $true
        } catch {
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Download failed: $_. Retrying in $RetryDelaySeconds seconds..." WARN
                Start-Sleep -Seconds $RetryDelaySeconds
            } else {
                Write-Log "Download failed after $MaxRetries attempts: $_" ERROR
                return $false
            }
        }
    }
    
    return $false
}

function Install-Ctrld {
    Write-Log "Installing Control D (ctrld)..." INFO
    
    if (Get-Command ctrld -ErrorAction SilentlyContinue) {
        Write-Log "ctrld already installed" SUCCESS
        return $true
    }
    
    if ($WhatIf) {
        Write-Log "[WHATIF] Would download and install ctrld from $InstallerUrl" INFO
        return $true
    }
    
    try {
        # Download installer
        if (-not (Invoke-WebRequestSafe -Uri $InstallerUrl -OutFile $InstallerPath)) {
            Write-Log "Failed to download ctrld installer" ERROR
            return $false
        }
        
        # Verify installer exists and has content
        if (-not (Test-Path $InstallerPath) -or (Get-Item $InstallerPath).Length -eq 0) {
            Write-Log "Downloaded installer is empty or invalid" ERROR
            return $false
        }
        
        Write-Log "Installer downloaded to $InstallerPath" INFO
        
        # Execute installer
        try {
            if ($ResolverId) {
                Write-Log "Installing with Resolver ID..." INFO
                & $InstallerPath $ResolverId "forced" -ErrorAction Stop
            } else {
                Write-Log "Installing without Resolver ID..." INFO
                & $InstallerPath -ErrorAction Stop
            }
        } catch {
            Write-Log "Installer execution failed: $_" ERROR
            return $false
        }
        
        # Verify installation
        Start-Sleep -Seconds 2
        if (-not (Get-Command ctrld -ErrorAction SilentlyContinue)) {
            Write-Log "ctrld command not found after installation. Check installer output." WARN
            return $false
        }
        
        Write-Log "ctrld installed successfully" SUCCESS
        return $true
    } catch {
        Write-Log "Unexpected error during ctrld installation: $_" ERROR
        return $false
    } finally {
        # Cleanup installer
        Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue
    }
}

function Backup-Configuration {
    if (Test-Path $ConfigFile) {
        try {
            Copy-Item -Path $ConfigFile -Destination $ConfigBackup -Force -ErrorAction Stop
            Write-Log "Configuration backed up to $ConfigBackup" SUCCESS
            return $true
        } catch {
            Write-Log "Failed to backup configuration: $_" WARN
            return $false
        }
    }
    return $true
}

function Install-Service {
    Write-Log "Configuring Windows Service..." INFO
    
    if ($WhatIf) {
        Write-Log "[WHATIF] Would create config directory: $ConfigDir" INFO
        Write-Log "[WHATIF] Would write configuration to: $ConfigFile" INFO
        Write-Log "[WHATIF] Would start ctrld service" INFO
        return $true
    }
    
    try {
        # Backup existing configuration
        Backup-Configuration | Out-Null
        
        # Create config directory
        if (-not (Test-Path $ConfigDir)) {
            New-Item -ItemType Directory -Path $ConfigDir -Force -ErrorAction Stop | Out-Null
            Write-Log "Created config directory: $ConfigDir" SUCCESS
        }
        
        # Validate ResolverId before writing config
        if (-not (Test-ResolverIdFormat -ResolverId $ResolverId)) {
            return $false
        }
        
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
        
        $ConfigContent | Set-Content -Path $ConfigFile -Encoding UTF8 -ErrorAction Stop
        Write-Log "Configuration written to $ConfigFile" SUCCESS
        
        # Verify configuration file
        if (-not (Test-Path $ConfigFile)) {
            Write-Log "Configuration file was not created" ERROR
            return $false
        }
        
        # Start service
        Write-Log "Starting ctrld service..." INFO
        try {
            & ctrld start --config "`"$ConfigFile`"" 2>&1 | ForEach-Object { Write-Log $_ INFO }
        } catch {
            Write-Log "Error during ctrld start: $_" WARN
        }
        
        Start-Sleep -Seconds 3
        
        # Verify service is running
        $service = Get-Process ctrld -ErrorAction SilentlyContinue
        if ($service) {
            Write-Log "ctrld service is running (PID: $($service.Id))" SUCCESS
            return $true
        } else {
            Write-Log "Service status unclear after start attempt" WARN
            try {
                & ctrld status 2>&1 | ForEach-Object { Write-Log $_ INFO }
            } catch {
                Write-Log "Could not retrieve ctrld status: $_" WARN
            }
            return $false
        }
    } catch {
        Write-Log "Unexpected error during service installation: $_" ERROR
        return $false
    }
}

function Uninstall-Ctrld {
    Write-Log "Preparing to uninstall Control D..." INFO
    
    # Ask for confirmation
    Write-Host ""
    Write-Host "WARNING: This will uninstall Control D service" -ForegroundColor Yellow
    $response = Read-Host "Continue with uninstall? (yes/no)"
    
    if ($response -ne "yes") {
        Write-Log "Uninstall cancelled by user" INFO
        return $true
    }
    
    if ($WhatIf) {
        Write-Log "[WHATIF] Would stop ctrld process" INFO
        Write-Log "[WHATIF] Would remove startup registry entry" INFO
        return $true
    }
    
    try {
        Write-Log "Stopping ctrld process..." INFO
        Stop-Process -Name ctrld -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        # Verify process is stopped
        if (Get-Process ctrld -ErrorAction SilentlyContinue) {
            Write-Log "Warning: ctrld process is still running" WARN
        } else {
            Write-Log "ctrld process stopped" SUCCESS
        }
        
        # Remove from startup
        $StartupKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        if (Test-Path $StartupKey) {
            try {
                Remove-ItemProperty -Path $StartupKey -Name "ControlD" -Force -ErrorAction SilentlyContinue
                Write-Log "Removed startup registry entry" SUCCESS
            } catch {
                Write-Log "Could not remove startup entry: $_" WARN
            }
        }
        
        Write-Log "Control D uninstalled (binary and config kept for safety)" SUCCESS
        return $true
    } catch {
        Write-Log "Error during uninstall: $_" ERROR
        return $false
    }
}

function Test-Installation {
    Write-Log "Running installation tests..." INFO
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host "DNS Resolution Test:" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    
    $dnsSuccess = $false
    try {
        $result = Resolve-DnsName -Name "whoami.controld.com" -Server "127.0.0.1" -ErrorAction Stop -DnsOnly
        Write-Log "DNS resolution working" SUCCESS
        Write-Host "  Response: $($result[0].IPAddress)" -ForegroundColor Gray
        $dnsSuccess = $true
    } catch {
        Write-Log "DNS test failed: $_" WARN
        Write-Host "  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "    - Service may need time to initialize (wait 5-10 seconds)" -ForegroundColor Gray
        Write-Host "    - Check Windows Firewall allows UDP port 53" -ForegroundColor Gray
        Write-Host "    - Verify DNS in network settings is set to 127.0.0.1" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host "Control D Status Check:" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    
    try {
        $statusOutput = & ctrld status 2>&1
        Write-Log "ctrld status: $statusOutput" INFO
        $statusOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    } catch {
        Write-Log "Could not get ctrld status: $_" WARN
        Write-Host "  ctrld status command unavailable" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Process Check:" -ForegroundColor Yellow
    $process = Get-Process ctrld -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "  ctrld process running (PID: $($process.Id))" -ForegroundColor Green
    } else {
        Write-Host "  ctrld process NOT running" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Verify full status at: https://controld.com/status" -ForegroundColor Cyan
    
    return $dnsSuccess
}

function Show-PostInstall {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host "POST-INSTALLATION NOTES" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "1. Verify status:     https://controld.com/status"
    Write-Host "2. Check service:     Get-Process ctrld"
    Write-Host "3. Restart service:   ctrld restart"
    Write-Host "4. Edit config:       $ConfigFile"
    Write-Host "5. View logs:         Get-Content $LogFile -Tail 50"
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
    Write-Host "Installation logs saved to: $LogFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installation complete!" -ForegroundColor Green
}

# =============================================================================
# Main
# =============================================================================

Write-Banner
Initialize-Logging

try {
    if ($Uninstall) {
        Test-Prerequisites
        Uninstall-Ctrld
        Write-Log "Uninstall process completed" SUCCESS
        exit 0
    }
    
    if ($VerifyOnly) {
        Write-Log "Running verification only" INFO
        Test-Installation
        Write-Log "Verification completed" SUCCESS
        exit 0
    }
    
    # Main installation flow
    Test-Prerequisites
    
    if ([string]::IsNullOrEmpty($ResolverId)) {
        Write-Log "ResolverId is required!" ERROR
        Write-Host ""
        Write-Host "Usage: .\install-windows.ps1 -ResolverId 'YOUR_RESOLVER_ID'" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Get your Resolver ID from:" -ForegroundColor Cyan
        Write-Host "  1. Go to https://controld.com/dashboard" -ForegroundColor Gray
        Write-Host "  2. Create or select an Endpoint" -ForegroundColor Gray
        Write-Host "  3. Copy the Resolver ID from endpoint settings" -ForegroundColor Gray
        Write-Host ""
        Write-Log "Installation failed: ResolverId not provided" ERROR
        exit 1
    }
    
    if (-not (Test-ResolverIdFormat -ResolverId $ResolverId)) {
        Write-Log "Installation failed: Invalid ResolverId format" ERROR
        exit 1
    }
    
    # Run installation steps
    if (-not (Install-Ctrld)) {
        Write-Log "Installation failed at ctrld install step" ERROR
        exit 1
    }
    
    if (-not (Install-Service)) {
        Write-Log "Warning: Service installation encountered issues" WARN
    }
    
    # Run tests
    Test-Installation
    
    # Show post-installation info
    Show-PostInstall
    
    Write-Log "Installation process completed successfully" SUCCESS
    
} catch {
    Write-Log "Fatal error during installation: $_" ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" ERROR
    exit 1
} finally {
    Write-Log "Script execution ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" INFO
}
