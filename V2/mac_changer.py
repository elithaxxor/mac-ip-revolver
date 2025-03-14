#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

#define MAX_INTERFACES 16
#define COUNTDOWN_MIN 30
#define COUNTDOWN_STEP 300 // 5 minutes in seconds

// Thread management
pthread_mutex_t thread_count_mutex = PTHREAD_MUTEX_INITIALIZER;
int active_threads = 0;

typedef struct {
    char interface[16];
    int thread_id;
} ThreadData;

void log_thread_count(const char* func_name) {
    pthread_mutex_lock(&thread_count_mutex);
    printf("[%s] Active threads: %d\n", func_name, active_threads);
    pthread_mutex_unlock(&thread_count_mutex);
}

void generate_random_mac(char *mac) {
    unsigned char bytes[6];
    for(int i = 0; i < 6; i++) {
        bytes[i] = rand() % 256;
        // Ensure multicast bit (least significant bit of first byte) is not set
        if(i == 0) bytes[i] &= 0xFE; 
    }
    snprintf(mac, 18, "%02X:%02X:%02X:%02X:%02X:%02X", 
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]);
}

void* change_mac(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    char mac[18];
    char command[128];
    
    pthread_mutex_lock(&thread_count_mutex);
    active_threads++;
    pthread_mutex_unlock(&thread_count_mutex);

    generate_random_mac(mac);
    
    // Bring interface down
    snprintf(command, sizeof(command), "sudo ip link set dev %s down", data->interface);
    system(command);
    // Add these after bringing interface down in change_mac()
    snprintf(command, sizeof(command), "sudo dhclient -r %s 2>/dev/null || sudo dhcpcd -k %s 2>/dev/null", 
            data->interface, data->interface);
    system(command);
    snprintf(command, sizeof(command), "sudo dhclient -r %s 2>/dev/null || sudo dhcpcd %s 2>/dev/null", 
            data->interface, data->interface);
    system(command);
    // Set new MAC
    snprintf(command, sizeof(command), "sudo ip link set dev %s address %s", data->interface, mac);
    system(command);
    
    
    // Bring interface up
    snprintf(command, sizeof(command), "sudo ip link set dev %s up", data->interface);
    system(command);
    // Add these after bringing interface up in change_mac()
    snprintf(command, sizeof(command), "sudo dhclient -r %s 2>/dev/null || sudo dhcpcd -k %s 2>/dev/null", 
            data->interface, data->interface);
    system(command);
    snprintf(command, sizeof(command), "sudo dhclient %s 2>/dev/null || sudo dhcpcd %s 2>/dev/null", 
            data->interface, data->interface);
    system(command);

    // DHCP release/renew
    sleep(2);  // Allow interface to settle
    snprintf(command, sizeof(command), "sudo dhclient -r %s 2>/dev/null || sudo dhcpcd -k %s 2>/dev/null",
            data->interface, data->interface);
    system(command);
    snprintf(command, sizeof(command), "sudo dhclient %s 2>/dev/null || sudo dhcpcd %s 2>/dev/null",
            data->interface, data->interface);
    system(command);

    printf("Changed MAC on %s to %s\n", data->interface, mac);
    log_thread_count(__func__);

    pthread_mutex_lock(&thread_count_mutex);
    active_threads--;
    pthread_mutex_unlock(&thread_count_mutex);
    
    free(data);
    return NULL;
}

void* countdown_timer(void* arg) {
    ThreadData* data = (ThreadData*)arg;
    
    pthread_mutex_lock(&thread_count_mutex);
    active_threads++;
    pthread_mutex_unlock(&thread_count_mutex);

    while(1) {
        for(int i = COUNTDOWN_MIN * 60; i > 0; i -= COUNTDOWN_STEP) {
            printf("[%s] Next MAC change in %d minutes...\n", 
                  data->interface, i/60);
            sleep(COUNTDOWN_STEP);
        }
        
        pthread_t thread;
        ThreadData* new_data = malloc(sizeof(ThreadData));
        strcpy(new_data->interface, data->interface);
        
        if(pthread_create(&thread, NULL, change_mac, new_data) != 0) {
            perror("Thread creation failed");
            free(new_data);
        }
    }
    
    pthread_mutex_lock(&thread_count_mutex);
    active_threads--;
    pthread_mutex_unlock(&thread_count_mutex);
    
    free(data);
    return NULL;
}

int main(int argc, char *argv[]) {
    if(argc != 2) {
        fprintf(stderr, "Usage: %s <interface|-all>\n", argv[0]);
        return 1;
    }

    srand(time(NULL));
    pthread_t threads[MAX_INTERFACES];
    int thread_count = 0;

    if(strcmp(argv[1], "-all") == 0) {
        // Get list of interfaces (simplified)
        char *interfaces[] = {"eth0", "wlan0"}; // Add more as needed
        int num_interfaces = sizeof(interfaces)/sizeof(interfaces[0]);

        for(int i = 0; i < num_interfaces; i++) {
            ThreadData* data = malloc(sizeof(ThreadData));
            strcpy(data->interface, interfaces[i]);
            data->thread_id = i+1;
            
            if(pthread_create(&threads[thread_count], NULL, change_mac, data) != 0) {
                perror("Thread creation failed");
                free(data);
            } else {
                thread_count++;
            }
        }
    } else {
        ThreadData* data = malloc(sizeof(ThreadData));
        strcpy(data->interface, argv[1]);
        data->thread_id = 1;
        
        if(pthread_create(&threads[thread_count], NULL, countdown_timer, data) != 0) {
            perror("Thread creation failed");
            free(data);
        } else {
            thread_count++;
        }
    }

    // Wait for all threads to complete
    for(int i = 0; i < thread_count; i++) {
        pthread_join(threads[i], NULL);
    }

    pthread_mutex_destroy(&thread_count_mutex);
    return 0;
}
