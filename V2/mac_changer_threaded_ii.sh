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
    echo "=============================================================================="
    echo "Starting MAC change process for $interface."
    OLD_MAC=$(get_current_mac "$interface")
    NEW_MAC=$(generate_random_mac)
    echo "Old MAC: $OLD_MAC"
    echo "To be new MAC: $NEW_MAC"
    # Update log file with timestamp
    LOG_FILE="$LOG_DIR/mac_change_$(date '+%Y-%m-%d_%H-%M-%S').log"
    log_message "Starting MAC change process for $interface."

    # Bring interface down, change MAC, and bring it back up
    log_message "Bringing down interface $interface..."
    sudo ifconfig "$interface" down
    
    log_message "Changing MAC of $interface from $OLD_MAC to $NEW_MAC"
    sudo macchanger -r "$interface"
    
    log_message "Bringing up interface $interface..."
    sudo ip link set dev "$interface" up
    
    # Renew DHCP lease
    log_message "Releasing current DHCP lease for $interface..."
    sleep 2  # Allow interface to settle
    dhclient -r "$interface" 2>/dev/null || dhcpcd -k "$interface" 2>/dev/null
    
    log_message "Requesting new DHCP lease for $interface..."
    dhclient "$interface" 2>/dev/null || dhcpcd "$interface" 2>/dev/null
    
    UPDATED_MAC=$(get_current_mac "$interface")
    if [[ "$UPDATED_MAC" != "$OLD_MAC" ]]; then
        log_message "MAC successfully changed to $UPDATED_MAC for $interface"
    else
        log_message "MAC change failed for $interface!"
    fi
    sudo dhclient -r && sudo dhclient $interface 

}

change_all_macs() {
    log_message "Changing MAC addresses for all network interfaces in parallel..."
    echo "=============================================================================="
    sudo iwconfig 
    sudo ifconfig 
    echo "=============================================================================="
    sudo dhclient -r 
    sleep $((RANDOM % 2 + 3))
    for interface in $(ls /sys/class/net | grep -v lo); do
        change_mac "$interface" &  # Run in background
        sudo dhclient "$interface" 
    done
    wait  # Wait for all background processes to finish
    sudo dhclient -r
    echo "MAC addresses changed and DHCP leases renewed."
    echo "All network interfaces have been changed to random MAC addresses."
    echo "You can now disconnect from the network and reconnect to apply the new MAC addresses."    
    iwconfig $interface down 
    sleep($((RANDOM % 1 + 3)))
    iwconfig $interface up
    echo "=============================================================================="
    sudo iwconfig 
    sudo ifconfig 
    echo "=============================================================================="
    sudo dhclient "$interface"
    echo "MAC addresses changed and DHCP leases renewed. New INFO $interface $NEW_MAC" 
    OLD_IP=$(ip addr show $interface | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    echo "Old IP: $OLD_IP"
    echo "Old MAC: $OLD_MAC"

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
    sudo dhclient -r && sudo dhclient $interface 
    sleep $((RANDOM % 4 + 3))

else
    countdown_timer "$INTERFACE" &
    wait  # Ensure the countdown and MAC change complete
fi