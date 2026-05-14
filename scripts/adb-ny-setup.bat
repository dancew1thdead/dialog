@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: NY-NY Ultimate v5.0 - Android Emulator ADB Setup Script (Windows)
:: ==============================================================================

echo =======================================================
echo NY-NY Ultimate v5.0 - Android Emulator Setup
echo =======================================================

:: Check if adb is installed
where adb >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] adb is not installed or not in PATH.
    echo Please install Android SDK Platform-Tools.
    pause
    exit /b 1
)

:: Ask for Control D Resolver ID
set /p RESOLVER_ID="Please enter your Control D Resolver ID (e.g., 12345abc): "

if "%RESOLVER_ID%"=="" (
    echo [ERROR] Resolver ID cannot be empty.
    pause
    exit /b 1
)

echo.
echo Starting configuration...

:: 1. Configure Private DNS (DoT)
echo.
echo [1/5] Configuring Private DNS (Control D)...
adb shell settings put global private_dns_mode hostname
adb shell settings put global private_dns_specifier "%RESOLVER_ID%.dns.controld.com"
echo Private DNS set to: %RESOLVER_ID%.dns.controld.com

:: 2. Set Timezone to New York (EST/EDT)
echo.
echo [2/5] Setting Timezone to America/New_York...
adb shell setprop persist.sys.timezone "America/New_York"
adb shell alarm set timezone America/New_York
echo Timezone configured.

:: 3. Set Language and Locale to US English
echo.
echo [3/5] Setting System Locale to en-US...
adb shell setprop persist.sys.locale en-US
adb shell setprop persist.sys.language en
adb shell setprop persist.sys.country US
echo Locale configured.

:: 4. Spoof GPS Location to JFK Airport, New York
echo.
echo [4/5] Spoofing GPS Location to JFK Airport (NY)...
adb shell appops set com.android.shell android:mock_location allow
adb emu geo fix -73.7781 40.6413
echo GPS location spoofed to JFK Airport.

:: 5. Disable Location Services
echo.
echo [5/5] Configuring Location Services...
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global ble_scan_always_enabled 0
echo Wi-Fi/BT scanning disabled.

:: Restart networking
echo.
echo Restarting networking to apply changes...
adb shell svc wifi disable
timeout /t 2 /nobreak >nul
adb shell svc wifi enable
timeout /t 3 /nobreak >nul

echo.
echo =======================================================
echo Setup Complete! Your emulator is now in New York.
echo =======================================================
echo To verify your setup, open the emulator browser and visit:
echo 1. https://controld.com/status
echo 2. https://ipinfo.io
echo 3. https://browserleaks.com/dns
echo.
pause
