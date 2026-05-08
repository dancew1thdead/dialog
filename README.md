# Control D - NY-NY ULTIMATE Package (JFK Cloaking)

## What's Included

| File | Description |
|------|-------------|
| `Control-D-Guide.pdf` | Complete Control D guide (Russian, 22 pages) |
| `profiles/NY-GCR-Ultimate.json` | Ultimate JFK cloaking profile (v4.0) |
| `scripts/install-ny.sh` | One-click NY-NY Ultimate setup script |
| `controld-guide.html` | Interactive Russian guide |

---

## Quick Start

### 1. Get Your Resolver ID

1. Go to [controld.com/dashboard](https://controld.com/dashboard)
2. Create a new Endpoint (or use existing one)
3. Copy the **Resolver ID** from the endpoint settings

### 2. Install Control D (Ultimate NY Setup)

**Linux / macOS:**
```bash
sudo chmod +x scripts/install-ny.sh
sudo ./scripts/install-ny.sh YOUR_RESOLVER_ID
```

### 3. Import the Profile

1. Go to [controld.com/dashboard](https://controld.com/dashboard)
2. Navigate to **Profiles** section
3. Click **Import Profile**
4. Select `profiles/NY-GCR-Ultimate.json`
5. Assign the profile to your Endpoint

### 4. Verify

Check in browser: https://controld.com/status
Or run: `curl https://ipinfo.io`

---

## Profile Architecture (v4.0)

```
Traffic Flow:
[Your Device] -> [Control D DNS] -> [JFK Proxy (NYC)] -> [Destination]

Rules Priority (highest first):
1. Custom Rules (Privacy & Verification)
2. Service Rules (100+ services forced to JFK)
3. Filters (Strict Ads, Malware, Tracking, IoT)
4. Geo Custom Rules (Non-US -> JFK)
5. Default Rule (Catch-all -> JFK)
```

### Key Features

- **100% Traffic** redirected through JFK (NYC)
- **Zero Traces**: Logging disabled, analytics/tracking blocked
- **Maximum Privacy**: Strict ad-blocking and malware protection
- **Global Geo-Rule**: All non-US traffic forced through JFK
- **No Bypasses**: Even VPN and analytics services are proxied for total anonymity

---

## Resources

- [Control D Documentation](https://docs.controld.com)
- [Control D Dashboard](https://controld.com/dashboard)
- [ctrld GitHub](https://github.com/Control-D-Inc/ctrld)
- [Status Page](https://controld.com/status)

---

*Profile version: 4.0 | Last updated: 2026-05-07*
*Created by Manus AI for родной*
