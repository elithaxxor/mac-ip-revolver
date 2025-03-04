#!/bin/bash

whatdoido() {
    echo "This script will:"
    echo "1. Bring the specified network interface down."
    echo "2. Change the MAC address to a random one."
    echo "3. Print the new MAC and compare it to the old one."
    echo "4. Bring the network interface back up."
    echo ""
    echo "Note: The script is set to change the MAC address of wlan0 by default."
    echo ""
}

change_mac() {
    read -p "[!] Enter the network interface (e.g., wlan0): " NETWORK_INTERFACE

    # Validate user input
    if [ -z "$NETWORK_INTERFACE" ]; then
        echo "Error: You must specify a network interface."
        exit 1
    fi

    echo "[!] Checking if macchanger is installed..."
    if ! command -v macchanger &> /dev/null; then
        echo "[-] macchanger not found. Installing macchanger..."
        sudo apt update
        sudo apt install -y macchanger
        echo "[+] macchanger installed" 
    else
        echo "[+] macchanger is already installed."
    fi

    # Get the current MAC address
    OLD_MAC=$(ifconfig $NETWORK_INTERFACE | grep -o -E '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}')
    echo "[!] Current MAC Address: $OLD_MAC"

    # Bring the network interface down
    echo "[!] Bringing $NETWORK_INTERFACE interface down..."
    sudo ifconfig $NETWORK_INTERFACE down

    # Change to a random MAC address
    echo "[!] Changing MAC address of $NETWORK_INTERFACE to a random one..."
    sudo macchanger -r $NETWORK_INTERFACE
    sleep $((RANDOM % 4 + 3))

    # Bring the network interface up
    echo "[!] Bringing $NETWORK_INTERFACE interface up..."
    sudo ifconfig $NETWORK_INTERFACE up

    # Get the new MAC address
    NEW_MAC=$(ifconfig $NETWORK_INTERFACE | grep -o -E '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}')
    echo "[+] New MAC Address: $NEW_MAC"

    # sleep random 3-6 seconds
    sleep $((RANDOM % 4 + 3))

    # Re-attach the network interface (DHCP - renews lease)
    sudo dhclient -r && sudo dhclient $NETWORK_INTERFACE

    sleep $((RANDOM % 4 + 3))

    # Compare old and new MAC addresses
    if [ "$OLD_MAC" != "$NEW_MAC" ]; then
        echo "[+] MAC address successfully changed!"
        echo "[+] Old MAC: $OLD_MAC, New MAC: $NEW_MAC"
    else
        echo "[-] MAC address change failed!"
        echo "[!] Old MAC: $OLD_MAC, New MAC: $NEW_MAC"
    fi

    sudo ifconfig 
    sudo iwconfig 
}

countdown_timer() {
    while true; do
        for ((i=30; i>0; i-=5)); do
            echo "Next MAC change in $i minutes..."
            sleep 300
        done
        change_mac
        sleep $((RANDOM % 4 + 3))
        sudo dhclient -r && sudo dhclient $NETWORK_INTERFACE

    done
}

whatdoido
countdown_timer