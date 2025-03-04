import time
import random
import re
import subprocess

def get_current_mac(interface="eth0"):
    """Get the current MAC address of the given interface."""
    try:
        output = subprocess.check_output(f"ifconfig {interface}", shell=True).decode()
        mac_address = re.search(r"(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)", output)
        if mac_address:
            return mac_address.group(0)
        return None
    except Exception as e:
        print(f"Error getting MAC address: {e}")
        return None

def generate_random_mac():
    """Generate a random MAC address."""
    return ":".join(f"{random.randint(0, 255):02x}" for _ in range(6))

def change_mac(interface="eth0"):
    """Change the MAC address of the given interface."""
    old_mac = get_current_mac(interface)
    new_mac = generate_random_mac()
    
    try:
        print(f"Changing MAC address from {old_mac} to {new_mac}")
        subprocess.call(f"sudo ifconfig {interface} down", shell=True)
        subprocess.call(f"sudo ifconfig {interface} hw ether {new_mac}", shell=True)
        subprocess.call(f"sudo ifconfig {interface} up", shell=True)
        
        updated_mac = get_current_mac(interface)
        
        if updated_mac == new_mac:
            print(f"MAC successfully changed to {updated_mac}")
        else:
            print("MAC change failed!")
    except Exception as e:
        print(f"Error changing MAC address: {e}")

def countdown_timer(interval=1800, echo_interval=300, interface="eth0"):
    """Run change_mac() every `interval` seconds while echoing every `echo_interval` seconds."""
    while True:
        for remaining in range(interval, 0, -echo_interval):
            print(f"Next MAC change in {remaining // 60} minutes...")
            time.sleep(echo_interval)
        change_mac(interface)

if __name__ == "__main__":
    countdown_timer()