# Quick Start Guide - GHOST-KICKER v1.0

## 🚀 Quick Execution Commands

### Linux/Ubuntu/Kali:
```bash
# 1. Make executable
chmod +x ghost-kicker.sh

# 2. Run with sudo
sudo ./ghost-kicker.sh
```

### Termux (Android):
```bash
# 1. Get root shell
su

# 2. Make executable
chmod +x ghost-kicker.sh

# 3. Run
./ghost-kicker.sh
```

## 📋 Typical Workflow

1. **Enable Monitor Mode** → Select option [1]
2. **Scan Networks** → Select option [2], wait for targets, press Ctrl+C
3. **Attack** → Select option [3] or [4], choose Auto-Target [2], pick number
4. **Exit Cleanly** → Select option [5] or press Ctrl+C

## 🔧 Install Dependencies (if needed)

### Ubuntu/Debian:
```bash
sudo apt update && sudo apt install -y aircrack-ng
```

### Termux:
```bash
pkg install aircrack-ng
```

## 📁 Scan Results Location

All scan results are saved to: `/tmp/ghost-kicker/`

- `scan_results.log` - Human-readable log
- `airodump-01.csv` - CSV for parsing
- `clients.txt` - Client list for auto-target
- `aps.txt` - Access point list for auto-target

## ⚙️ Smart Interval Recommendations

- **Stealth Mode**: 2-5 seconds (default: 2s)
- **Balanced**: 1-2 seconds
- **Aggressive**: 0.5-1 second (higher detection risk)

## 🧹 Manual Cleanup (if needed)

```bash
# Kill airodump-ng
sudo killall airodump-ng

# Kill aireplay-ng
sudo killall aireplay-ng

# Stop monitor mode (replace wlan0mon with your interface)
sudo airmon-ng stop wlan0mon

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

## ⚠️ Important Notes

- **Always run as root**
- **Press Ctrl+C to stop scanning or attacks**
- **Script auto-cleans on exit**
- **Clear /tmp/ghost-kick/ after use for privacy**
