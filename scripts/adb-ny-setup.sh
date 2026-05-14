#!/bin/bash

# ==============================================================================
# NY-NY Ultimate v5.0 - Android Emulator ADB Setup Script
# ==============================================================================
# This script configures an Android emulator via ADB to use Control D NY-NY
# Ultimate profile, spoofs location to JFK (New York), sets timezone, and
# configures system language to US English.
# ==============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🗽 NY-NY Ultimate v5.0 - Android Emulator Setup${NC}"
echo "======================================================="

# Check if adb is installed
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: adb is not installed or not in PATH.${NC}"
    echo "Please install Android SDK Platform-Tools."
    exit 1
fi

# Check if device is connected
DEVICE_COUNT=$(adb devices | grep -v "List of devices attached" | grep "device$" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No Android emulator/device found.${NC}"
    echo "Please start your emulator and ensure USB debugging is enabled."
    exit 1
fi

if [ "$DEVICE_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}Warning: Multiple devices found. Using the default one.${NC}"
    echo "To target a specific device, set ANDROID_SERIAL environment variable."
fi

# Ask for Control D Resolver ID
echo -e "\n${YELLOW}Please enter your Control D Resolver ID (e.g., 12345abc):${NC}"
read -r RESOLVER_ID

if [ -z "$RESOLVER_ID" ]; then
    echo -e "${RED}Error: Resolver ID cannot be empty.${NC}"
    exit 1
fi

echo -e "\n${GREEN}Starting configuration...${NC}"

# 1. Configure Private DNS (DoT)
echo -e "\n${YELLOW}[1/5] Configuring Private DNS (Control D)...${NC}"
adb shell settings put global private_dns_mode hostname
adb shell settings put global private_dns_specifier "$RESOLVER_ID.dns.controld.com"
echo "Private DNS set to: $RESOLVER_ID.dns.controld.com"

# 2. Set Timezone to New York (EST/EDT)
echo -e "\n${YELLOW}[2/5] Setting Timezone to America/New_York...${NC}"
adb shell setprop persist.sys.timezone "America/New_York"
adb shell alarm set timezone America/New_York
echo "Timezone configured."

# 3. Set Language and Locale to US English
echo -e "\n${YELLOW}[3/5] Setting System Locale to en-US...${NC}"
adb shell setprop persist.sys.locale en-US
adb shell setprop persist.sys.language en
adb shell setprop persist.sys.country US
echo "Locale configured."

# 4. Spoof GPS Location to JFK Airport, New York
# JFK Coordinates: 40.6413° N, 73.7781° W
echo -e "\n${YELLOW}[4/5] Spoofing GPS Location to JFK Airport (NY)...${NC}"
# Enable mock locations
adb shell appops set com.android.shell android:mock_location allow
# Set location using geo command (works on most emulators)
adb emu geo fix -73.7781 40.6413
echo "GPS location spoofed to JFK Airport."

# 5. Disable Location Services (Optional but recommended for privacy)
echo -e "\n${YELLOW}[5/5] Configuring Location Services...${NC}"
# Turn off Wi-Fi and Bluetooth scanning
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global ble_scan_always_enabled 0
echo "Wi-Fi/BT scanning disabled."

# Restart networking to apply DNS changes
echo -e "\n${YELLOW}Restarting networking to apply changes...${NC}"
adb shell svc wifi disable
sleep 2
adb shell svc wifi enable
sleep 3

echo -e "\n${GREEN}=======================================================${NC}"
echo -e "${GREEN}✅ Setup Complete! Your emulator is now in New York. 🗽${NC}"
echo -e "======================================================="
echo "To verify your setup, open the emulator browser and visit:"
echo "1. https://controld.com/status"
echo "2. https://ipinfo.io"
echo "3. https://browserleaks.com/dns"
