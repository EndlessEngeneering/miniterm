#!/usr/bin/env bash
brew install nmap
# Automatically detect local network subnet
SUBNET=$(ip route show default 2>/dev/null | awk '/default/ {print $3}' | sed 's/\.[0-9]*$/.0\/24/')

# Fallback for macOS / systems without 'ip route'
if [ -z "$SUBNET" ]; then
    SUBNET=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}' | sed 's/\.[0-9]*$/.0\/24/')
fi

# Fallback if detection fails
if [ -z "$SUBNET" ]; then
    SUBNET="192.168.1.0/24"
fi

echo "Scanning local network ($SUBNET)... Please wait."
echo "------------------------------------------------"

# Arrays to store IPs and Hostnames
ips=()
hostnames=()

# Run nmap ping scan to discover active hosts and resolve hostnames
while read -r ip hostname; do
    if [ -n "$ip" ]; then
        ips+=("$ip")
        if [ -n "$hostname" ] && [ "$hostname" != "$ip" ]; then
            hostnames+=("$hostname")
        else
            hostnames+=("Unknown Device")
        fi
    fi
done < <(nmap -sn "$SUBNET" 2>/dev/null | awk '
    /Nmap scan report for/ {
        if ($NF ~ /^\(.*\)$/) {
            ip = substr($NF, 2, length($NF)-2)
            name = $5
        } else {
            ip = $NF
            name = "Unknown Device"
        }
        print ip, name
    }
')

# Check if any devices were found
if [ ${#ips[@]} -eq 0 ]; then
    echo "No devices found on subnet $SUBNET."
    exit 1
fi

# Display numbered list of devices (Names only)
echo "Discovered Devices:"
echo "------------------------------------------------"
for i in "${!hostnames[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${hostnames[$i]}"
done
echo "------------------------------------------------"

# Prompt user for selection
while true; do
    read -rp "Enter the number of the device to view its IP (or 'q' to quit): " choice
    
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        echo "Exiting."
        exit 0
    fi

    # Validate numeric input within valid range
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ips[@]}" ]; then
        index=$((choice - 1))
        echo ""
        echo "================================================"
        echo " Device Name : ${hostnames[$index]}"
        echo " IP Address  : ${ips[$index]}"
        echo "================================================"
        break
    else
        echo "Invalid choice. Please enter a number between 1 and ${#ips[@]}."
    fi
done
