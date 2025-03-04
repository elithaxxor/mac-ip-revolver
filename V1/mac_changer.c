#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#define INTERFACE "wlan0"
#define CHANGE_INTERVAL 1800 // 30 minutes
#define COUNTDOWN_STEP 300   // 5 minutes

void get_current_mac(char *interface, char *mac_address) {
    FILE *fp;
    char cmd[100];
    snprintf(cmd, sizeof(cmd), "cat /sys/class/net/%s/address", interface);
    
    fp = popen(cmd, "r");
    if (fp == NULL) {
        perror("Failed to get MAC address");
        exit(1);
    }
    
    fgets(mac_address, 18, fp);
    pclose(fp);
}

void generate_random_mac(char *mac_address) {
    srand(time(NULL));
    snprintf(mac_address, 18, "%02X:%02X:%02X:%02X:%02X:%02X",
             rand() % 256, rand() % 256, rand() % 256,
             rand() % 256, rand() % 256, rand() % 256);
}

void change_mac(char *interface) {
    char old_mac[18], new_mac[18], cmd[200];
    
    get_current_mac(interface, old_mac);
    generate_random_mac(new_mac);
    
    printf("[!] Changing MAC address from %s to %s\n", old_mac, new_mac);
    
    snprintf(cmd, sizeof(cmd), "sudo ifconfig %s down", interface);
    system(cmd);
    
    snprintf(cmd, sizeof(cmd), "sudo macchanger -m %s %s", new_mac, interface);
    system(cmd);
    
    snprintf(cmd, sizeof(cmd), "sudo ifconfig %s up", interface);
    system(cmd);
    
    char updated_mac[18];
    get_current_mac(interface, updated_mac);
    
    if (strcmp(new_mac, updated_mac) == 0) {
        printf("[+] MAC successfully changed to %s\n", updated_mac);
    } else {
        printf("[-] MAC change failed!\n");
    }
}

void countdown_timer(char *interface) {
    while (1) {
        for (int remaining = CHANGE_INTERVAL; remaining > 0; remaining -= COUNTDOWN_STEP) {
            printf("Next MAC change in %d minutes...\n", remaining / 60);
            sleep(COUNTDOWN_STEP);
        }
        change_mac(interface);
    }
}

int main() {
    printf("\n[+] MAC Changer Script Starting...\n");
    printf("[!] Interface: %s\n", INTERFACE);
    countdown_timer(INTERFACE);
    return 0;
}
