#📡 MAC Address Changer Script
##📝 Overview

V1 - Uses macchanger, which reverts your mac to its original state once the loop interval quit. 
V2 - Includes 'all', where you can change the local IP and mac at the same time during the loop. 

Written in C, Python and Bash. 

###To Run In C: 
```bash
gcc mac_changer.c -o mac_changer -lpthread
sudo ./mac_changer eth0  # For single interface
sudo ./mac_changer -all  # For all interfaces

valgrind --leak-check=full ./mac_changer eth0
#Memory management verified with:
```

###This Bash script automates the process of changing the MAC address of a network interface on a Linux system. It allows the user to:

Bring the specified network interface down.

Change the MAC address to a random one.

Display countdown notifications before each MAC change.

Compare the old MAC address with the new one to confirm the change.

Bring the network interface back up.

Run continuously, updating the MAC address every 30 minutes while displaying countdown messages every 5 minutes.

This script is ideal for users who require periodic MAC address changes for privacy, security, or network testing purposes.

#🚀 Features

✅ Automated MAC Address Change – The script continuously updates your MAC address every 30 minutes.

✅ Countdown Timer – Every 5 minutes, the script reminds you of the next MAC change.

✅ MAC Address Comparison – Displays both the old and new MAC addresses to confirm a successful change.

✅ Automatic Dependency Check – Installs macchanger if it is missing on the system.

✅ User-Friendly – Allows you to select the network interface dynamically.

✅ Looping Execution – Runs indefinitely, ensuring periodic MAC address changes.

✅ Minimal User Interaction – Set it and forget it!

✅ DHCP Support
- Automatically handles DHCP release/renew for:
  - `dhclient` (Debian/Ubuntu)
  - `dhcpcd` (Arch/Raspbian)
- Adds 2-second delay after interface activation to ensure proper DHCP operations

🛠️ Installation & Requirements

#📌 Prerequisites

This script is designed for Linux-based operating systems (Ubuntu, Debian, Kali Linux, etc.) and requires:

macchanger – A command-line tool for changing MAC addresses.

ifconfig – A networking command (part of net-tools).

sudo/root permissions – Required to modify network settings.

#🔧 Installing Dependencies (if needed)

If macchanger or ifconfig are missing, you can install them manually:

sudo apt update && sudo apt install -y macchanger net-tools

#📜 Usage Instructions

1️⃣ Run the Script

Clone the repository (or download the script) and navigate to its location:

git clone https://github.com/yourusername/mac-changer-script.git
cd mac-changer-script

Give execution permissions:

chmod +x mac_changer.sh

Run the script:

./mac_changer.sh

##2️⃣ Enter Network Interface

You will be prompted to enter the network interface (e.g., wlan0 or eth0).

If you are unsure of your interface, run:

ifconfig

or

ip a

3️⃣ Let It Run!

Once started, the script will:

Display a countdown every 5 minutes.

Change your MAC address every 30 minutes.

Compare and verify the new MAC.

#📢 Example Output
```bash
[!] Enter the network interface (e.g., wlan0): wlan0
[!] Checking if macchanger is installed...
[+] macchanger is already installed.
[!] Current MAC Address: 00:1A:2B:3C:4D:5E
Next MAC change in 30 minutes...
Next MAC change in 25 minutes...
Next MAC change in 20 minutes...
...
[!] Changing MAC address of wlan0 to a random one...
[+] New MAC Address: 86:E3:20:19:18:CA
[+] MAC address successfully changed!
```
⚠️ Important Notes

Requires Root Permissions – The script modifies network settings, so you must run it as root.

May Disconnect Network – Since the script brings the interface down temporarily, you may experience brief connectivity loss.

Permanent vs. Temporary Changes – macchanger makes temporary changes. If you restart your device, the MAC address will revert to its original value.

Use with Caution – Some networks may block devices that frequently change MAC addresses.

🛑 Stop the Script

If you need to stop the script at any time, use:

CTRL + C

🏆 Why Use This Script?

🔹 Enhance Privacy – Avoid being tracked by changing your MAC address regularly.

🔹 Network Testing – Simulate different devices on a network.

🔹 Bypass MAC Filtering – Some networks block specific MAC addresses; changing yours may help.

🔹 Security Research – Useful for penetration testers and cybersecurity professionals.

## About Me
This project, `mac_changer`, is a utility designed to change the MAC address of a network interface on a Unix-based system. It provides a simple and efficient way to modify the MAC address, which can be useful for various purposes such as network testing, privacy enhancement, or bypassing MAC address-based restrictions.

🤝 Contributing

Have suggestions for improvements? Feel free to fork the repo, create a pull request, or submit an issue!

git clone https://github.com/yourusername/mac-changer-script.git

📜 License

This project is licensed under the MIT License – you are free to use, modify, and distribute it as you like.

📬 Contact

For questions or contributions, reach out via:

GitHub Issues: https://github.com/yourusername/mac-changer-script/issues

Email: your.email@example.com
