# 🎛️ Control D - NY-GCR Profile Package

## What's Included

| File | Description |
|------|-------------|
| `docs/controld-guide.html` | Beautiful interactive HTML guide |
| `profiles/NY-GCR-Profile.json` | JFK cloaking profile configuration |
| `scripts/install-linux-mac.sh` | Installation script for Linux/macOS |
| `scripts/install-windows.ps1` | Installation script for Windows |

---

## Quick Start

### 1. Get Your Resolver ID

1. Go to [controld.com/dashboard](https://controld.com/dashboard)
2. Create a new Endpoint (or use existing one)
3. Copy the **Resolver ID** from the endpoint settings

### 2. Install Control D

**Linux / macOS:**
```bash
sudo bash scripts/install-linux-mac.sh YOUR_RESOLVER_ID
```

**Windows (PowerShell as Admin):**
```powershell
.\scripts\install-windows.ps1 -ResolverId "YOUR_RESOLVER_ID"
```

### 3. Import the Profile

1. Go to [controld.com/dashboard](https://controld.com/dashboard)
2. Navigate to **Profiles** section
3. Click **Import Profile**
4. Select `profiles/NY-GCR-Profile.json`
5. Assign the profile to your Endpoint

### 4. Verify

Open in browser: https://controld.com/status

---

## Profile Architecture

```
Traffic Flow:
[Your Device] → [Control D DNS] → [JFK Proxy] → [Destination]

Rules Priority (highest first):
1. Custom Rules (specific domains)
2. Service Rules (400+ services)
3. Filters (category-based)
4. Geo Custom Rules (country-based)
5. Default Rule (catch-all)
```

### Key Features

- **60+ services** redirected through JFK (NYC)
- **Geo Rule**: All non-US destinations auto-redirect to JFK
- **Default Rule**: Everything through JFK
- **Filters**: Malware, Ads (medium), Typo-squatting, IoT telemetry
- **Bypassed**: VPN services, some analytics for compatibility

---

## Resources

- 📚 [Control D Documentation](https://docs.controld.com)
- 🎛️ [Control D Dashboard](https://controld.com/dashboard)
- 💻 [ctrld GitHub](https://github.com/Control-D-Inc/ctrld)
- 📊 [Status Page](https://controld.com/status)

---

*Version 3.0 | Last updated: 2025-05-08*