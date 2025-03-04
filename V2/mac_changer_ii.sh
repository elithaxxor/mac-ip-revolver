#!/bin/bash

# Set logging directory
LOG_DIR="$PWD/logs"
LOG_FILE=""
CHANGE_INTERVAL=1800  # 30 minutes
COUNTDOWN_STEP=300    # 5 minutes

mkdir -p "$LOG_DIR" # Ensure log directory exists

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

get_current_mac() {
    local interface="$1"
    ip link show "$interface" | awk '/link\/ether/ {print $2}'
}

generate_random_mac() {
    printf "%02X:%02X:%02X:%02X:%02X:%02X" $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

change_mac() {
    local interface="$1"
    OLD_MAC=$(get_current_mac "$interface")
    NEW_MAC=$(generate_random_mac)
    
    # Update log file with timestamp
    LOG_FILE="$LOG_DIR/mac_change_$(date '+%Y-%m-%d_%H-%M-%S').log"
    log_message "Starting MAC change process for $interface."

    # Bring interface down, change MAC, and bring it back up
    log_message "Bringing down interface $interface..."
    sudo ifconfig "$interface" down
    
    log_message "Changing MAC of $interface from $OLD_MAC to $NEW_MAC"
    sudo macchanger -r "$interface"
    
    log_message "Bringing up interface $interface..."
    sudo ifconfig "$interface" up
    
    # Renew DHCP lease
    log_message "Releasing current DHCP lease for $interface..."
    sudo dhclient -r "$interface"
    
    log_message "Requesting new DHCP lease for $interface..."
    sudo dhclient "$interface"
    
    UPDATED_MAC=$(get_current_mac "$interface")
    if [[ "$UPDATED_MAC" != "$OLD_MAC" ]]; then
        log_message "MAC successfully changed to $UPDATED_MAC for $interface"
    else
        log_message "MAC change failed for $interface!"
    fi
}

change_all_macs() {
    log_message "Changing MAC addresses for all network interfaces in parallel..."
    for interface in $(ls /sys/class/net | grep -v lo); do
        change_mac "$interface" &  # Run in background
    done
    wait  # Wait for all background processes to finish
}

countdown_timer() {
    local interface="$1"
    while true; do
        for ((i=CHANGE_INTERVAL; i>0; i-=COUNTDOWN_STEP)); do
            echo "Next MAC change for $interface in $((i / 60)) minutes..."
            sleep $COUNTDOWN_STEP
        done
        change_mac "$interface" &  # Run in background
        wait  # Ensure it completes before starting another countdown
    done
}

# Ask for interface input
read -p "Enter the network interface to change (or '-all' for all interfaces): " INTERFACE

if [[ "$INTERFACE" == "-all" ]]; then
    change_all_macs
else
    countdown_timer "$INTERFACE" &
    wait  # Ensure the countdown and MAC change complete
fi