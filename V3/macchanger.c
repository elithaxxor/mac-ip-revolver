#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <stdbool.h> // For bool type
// Set default interface based on operating system
#if defined(__APPLE__) || defined(__MACH__)
    #define DEFAULT_INTERFACE "en0"    // macOS/Darwin
# elif defined(__linux__)
    #define DEFAULT_INTERFACE "wlan0"   
#endif

#define CHANGE_INTERVAL 1800 // 30 minutes
#define COUNTDOWN_STEP 300   // 5 minutes
#include <readline/readline.h>
#include <readline/history.h>

void show_interactive_menu() {
    printf("\nSelect network interface:\n");
    printf("1) eth0\n");
    #if defined(__APPLE__) || defined(__MACH__)
        printf("2) en0 (default for macOS)\n");
    #else
        printf("2) wlan0 (default for Linux)\n");
    #endif
    printf("3) Enter custom interface\n");
    printf("4) DNS Lookup\n");
    printf("5) Exit\n");
}

// Function to perform DNS lookup using system commands
void perform_dns_lookup() {
    char hostname[256] = "google.com"; // Default value
    char cmd[512];
    FILE *fp;
    char line[1024];
    
    // Simpler input handling. then 
    // Read user input and remove newline character
    if (fgets(hostname, sizeof(hostname), stdin) != NULL) {
        hostname[strcspn(hostname, "\n")] = 0;  // Remove newline character
        print(f"[+] User {}")
        if (strlen(hostname) == 0) {
            strcpy(hostname, "google.com");
        }
    }
    
    // Create a results file to save output
    FILE *resultsFile = fopen("dns_results.txt", "w");
    if (!resultsFile) {
        perror("Failed to create results file");
        return;
    }
    
    printf("\n[+] Running DNS lookup for %s\n", hostname);
    printf("[+] Results:\n");
    
    // Using dig command to get IP addresses
    snprintf(cmd, sizeof(cmd), "dig +short %s", hostname);
    
    fp = popen(cmd, "r");
    if (fp == NULL) {
        perror("Failed to run dig command");
        fclose(resultsFile);
        return;
    }
    
    // Print and save each IP address
    printf("  IP Addresses:\n");
    bool has_results = false;
    
    while (fgets(line, sizeof(line), fp) != NULL) {
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) > 0) {
            has_results = true;
            printf("    %s\n", line);
            fprintf(resultsFile, "IP: %s\n", line);
            
            // For each IP, try to get the hostname
            char reverse_cmd[512];
            snprintf(reverse_cmd, sizeof(reverse_cmd), "dig +short -x %s", line);
            FILE *rfp = popen(reverse_cmd, "r");
            if (rfp) {
                char rline[1024];
                if (fgets(rline, sizeof(rline), rfp) != NULL) {
                    // Remove newline
                    rline[strcspn(rline, "\n")] = 0;
                    if (strlen(rline) > 0) {
                        printf("      Hostname: %s\n", rline);
                        fprintf(resultsFile, "  Hostname: %s\n", rline);
                    }
                }
                pclose(rfp);
            }
        }
    }
    
    if (!has_results) {
        printf("    No IP addresses found for %s\n", hostname);
        fprintf(resultsFile, "No IP addresses found for %s\n", hostname);
    }
    
    pclose(fp);
    fclose(resultsFile);
    printf("\n[+] Results saved to dns_results.txt\n");
}

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
    // Add these after bringing interface up in change_mac()
    snprintf(cmd, sizeof(cmd), "sudo dhclient -r %s 2>/dev/null || sudo dhcpcd -k %s 2>/dev/null", 
            interface, interface);
    system(cmd);
    snprintf(cmd, sizeof(cmd), "sudo dhclient %s 2>/dev/null || sudo dhcpcd %s 2>/dev/null", 
            interface, interface);
    system(cmd);
        char updated_mac[18];
    get_current_mac(interface, updated_mac);
    
    if (strcmp(new_mac, updated_mac) == 0) {
        printf("[+] MAC successfully changed to %s\n", updated_mac);
            // Wait for all threads to complete

        pthread_mutex_destroy(&thread_count_mutex);
        return 0;
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

int main(int argc, char *argv[]) {
    char *interface = NULL;
    int opt;
    
    // New argument handling
    while ((opt = getopt(argc, argv, "i:d")) != -1) {
        switch (opt) {
            case 'i': 
                interface = optarg;
                break;
            case 'd':
                perform_dns_lookup();
                return 0;
            default:
                fprintf(stderr, "Usage: %s [-i interface] [-d for DNS lookup]\n", argv[0]);
                return 1;
        }
    }

    // Interactive mode
    if (!interface) {
        show_interactive_menu();
        char *choice = readline("Choice [1-5]: ");
        int choice_num = atoi(choice);
        
        switch (choice_num) {
            case 1: interface = "eth0"; break;
            case 2: interface = DEFAULT_INTERFACE; break;
            case 3: 
                interface = readline("Enter interface name: ");
                break;
            case 4:
                free(choice);
                perform_dns_lookup();
                return 0;
            case 5: 
                free(choice);
                return 0;
            default:
                fprintf(stderr, "Invalid choice\n");
                free(choice);
                return 1;
        }
        free(choice);
    }
    
    // If still no interface specified, use default
    if (!interface) {
        interface = DEFAULT_INTERFACE;
    }
    
    printf("\n[+] MAC Changer Script Starting...\n");
    printf("[!] Interface: %s\n", interface);
    countdown_timer(interface);
    return 0;
}
