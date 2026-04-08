# GHOST-KICKER v1.0 - Professional WiFi Deauthentication Tool

A professional-grade WiFi Deauthentication Tool for Linux/Termux (Rooted) using Bash. Features a modular CLI interface with stealth capabilities and auto-target functionality.

## 🚨 Disclaimer

**This tool is for educational and authorized testing purposes only.** Unauthorized use of this tool on networks you do not own or have explicit permission to test is illegal and unethical. Use responsibly.

## 📋 Features

- **Modular Menu Interface**: Clean CLI with 5 main options
- **Auto-Detection**: Automatically detects wireless interfaces (wlan0, wlan1, etc.)
- **Network Scanning**: Uses airodump-ng to scan and log networks
- **Targeted Attacks**: Deauth specific clients on a network
- **Chaos Mode**: Deauth all clients on a specific BSSID
- **Auto-Target Feature**: Parse airodump-ng CSV files and select clients by number
- **Smart Interval**: Stealth mode with configurable intervals to avoid WIDS detection
- **Graceful Cleanup**: SIGINT (Ctrl+C) handler restores network state automatically
- **Professional UI**: ANSI color-coded output for high-end hacking tool aesthetics
- **Scan Logging**: Saves results to temporary log for easy MAC address copy-pasting

## 🔧 System Requirements

- **OS**: Linux or Termux (Android)
- **Privileges**: Root access required
- **Dependencies**: aircrack-ng suite

## 📦 Installation

### For Ubuntu/Debian/Kali Linux:
```bash
sudo apt update
sudo apt install -y aircrack-ng
```

### For Termux (Android):
```bash
pkg update
pkg install aircrack-ng
```

### For Arch Linux:
```bash
sudo pacman -S aircrack-ng
```

## 🚀 Usage

### Step 1: Make the script executable
```bash
chmod +x ghost-kicker.sh
```

### Step 2: Run with root privileges
```bash
sudo ./ghost-kicker.sh
```

### For Termux:
```bash
su
./ghost-kicker.sh
```

## 📖 Menu Options

### [1] Enable Monitor Mode
- Auto-detects wireless interface (wlan0, wlan1, etc.)
- Kills interfering processes
- Enables monitor mode for packet injection
- Shows the monitor interface name (e.g., wlan0mon)

### [2] Scan Networks
- Runs airodump-ng on the monitor interface
- Captures nearby WiFi networks and connected clients
- Saves results to CSV format in `/tmp/ghost-kicker/`
- Creates a log file for easy MAC address copying
- Press Ctrl+C when you see your target network

### [3] Target Specific Attack
- **Manual Input**: Type the BSSID and Client MAC manually
- **Auto-Target**: Select from parsed scan results using numbers
- Configurable smart interval for stealth
- Deauths a specific client from a network

### [4] Chaos Mode
- **Manual Input**: Type the target BSSID manually
- **Auto-Target**: Select network from scan results
- Deauthenticates ALL clients on the target network
- Configurable smart interval for stealth
- ⚠️ Use with caution - affects entire network

### [5] Disable Monitor Mode & Exit
- Stops monitor mode
- Restores network adapter to managed mode
- Restarts NetworkManager/wpa_supplicant
- Exits cleanly

## 🎯 Auto-Target Feature

The Auto-Target feature parses the latest airodump-ng CSV file and presents:

1. **Client Selection**: Lists all connected clients with numbers (1, 2, 3...)
2. **Network Selection**: Lists all detected networks with numbers
3. **Easy Selection**: Simply type a number to select your target
4. **Auto-Fill**: Automatically fills BSSID and MAC addresses

### How to Use Auto-Target:
1. Enable Monitor Mode [1]
2. Scan Networks [2] and wait for clients to appear
3. Press Ctrl+C to stop scanning
4. Select Target Specific Attack [3] or Chaos Mode [4]
5. Choose option [2] Auto-Target
6. Select the client/network number from the list
7. Configure smart interval and start attack

## 🔒 Smart Interval (Stealth Mode)

The Smart Interval feature sends deauth packets at configurable intervals to avoid detection by basic Wireless Intrusion Detection Systems (WIDS).

- **Default**: 2 seconds
- **Recommended**: 2-5 seconds for stealth
- **Aggressive**: 0.5-1 second (higher detection risk)
- **Configure**: Prompted before each attack

## 🧹 Cleanup & Safety

The script includes a robust cleanup handler that triggers on:
- Ctrl+C (SIGINT)
- Script exit
- Manual cleanup via menu option [5]

Cleanup actions:
- Stops all airodump-ng processes
- Stops all aireplay-ng processes
- Disables monitor mode
- Restores network adapter to managed mode
- Restarts NetworkManager (Linux) or wpa_supplicant (Termux)

## 📁 File Locations

- **Script**: `ghost-kicker.sh`
- **Temp Directory**: `/tmp/ghost-kicker/`
- **Scan Log**: `/tmp/ghost-kicker/scan_results.log`
- **CSV File**: `/tmp/ghost-kicker/airodump-01.csv`
- **Client List**: `/tmp/ghost-kicker/clients.txt` (auto-target)
- **AP List**: `/tmp/ghost-kicker/aps.txt` (auto-target)

## 🎨 Color Scheme

- **Red**: Attacks, warnings, errors
- **Green**: Success messages, confirmations
- **Yellow**: Warnings, informational messages
- **Blue**: General information
- **Magenta**: Banner/headers
- **Cyan**: Menu options, details

## ⚠️ Troubleshooting

### "No wireless interface found"
- Check if your WiFi adapter is connected
- Try manual interface specification in the script
- Ensure drivers are installed

### "aircrack-ng suite not found"
- Install aircrack-ng using the commands above
- Verify installation with: `which aircrack-ng`

### "Monitor mode not enabled"
- Ensure you ran option [1] first
- Check for conflicting processes
- Try killing interfering processes manually: `airmon-ng check kill`

### "No clients found in scan results"
- Ensure devices are connected to the target network
- Run scan for longer duration
- Move closer to the target network

### Script doesn't run
- Ensure executable permissions: `chmod +x ghost-kicker.sh`
- Run with root: `sudo ./ghost-kicker.sh`
- Check bash is installed: `which bash`

## 🔐 Security Notes

- Always obtain written permission before testing
- Use only on networks you own or have authorization to test
- This tool leaves logs - clear `/tmp/ghost-kicker/` after use
- Smart interval reduces but does not eliminate detection risk
- Modern WIDS/WIPS may still detect deauth attacks

## 📝 Function Reference

### Core Functions:
- `check_root()` - Verifies root privileges
- `check_dependencies()` - Checks aircrack-ng installation
- `detect_interface()` - Auto-detects wireless interface
- `enable_monitor_mode()` - Enables monitor mode
- `disable_monitor_mode()` - Disables monitor mode
- `scan_networks()` - Scans for WiFi networks
- `parse_csv_clients()` - Parses CSV for auto-target
- `target_specific_attack()` - Targeted deauth attack
- `chaos_mode()` - Broadcast deauth attack
- `cleanup_handler()` - SIGINT handler for cleanup
- `show_menu()` - Main menu interface

## 📄 License

This tool is for educational purposes. Use responsibly and ethically.

## 👤 Author

Created by Cascade AI using SWE-1.6 capability.

---

**Remember**: With great power comes great responsibility. Use this tool ethically and legally.
