#pragma once

#include <linux/limits.h>
#include <sys/types.h>

#include <assert.h>
#include <inttypes.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>

#include <net/ethernet.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <pcap.h>

#include <rte_build_config.h>
#include <rte_byteorder.h>
#include <rte_common.h>
#include <rte_eal.h>
#include <rte_errno.h>
#include <rte_ethdev.h>
#include <rte_lcore.h>
#include <rte_malloc.h>
#include <rte_mbuf.h>
#include <rte_per_lcore.h>
#include <rte_thash.h>
#include <rte_flow.h>
#include <rte_version.h>
#include <rte_build_config.h>

#define MD_PREFETCH_DISTANCE 3
#define PKT_PREFETCH_DISTANCE 3

// Define a structure for MAC-to-queue mapping
struct mac_to_queue_map {
    uint8_t mac[RTE_ETHER_ADDR_LEN];
    uint16_t queue_id;
    struct rte_flow *flow;  // Pointer to the created flow rule
};

/* This is a catch all filter, since we have a forwarding rule set for all the other MAC
 * this one will catch any packets that are not matched by the other rules and drop them.
 */
static int create_drop_filter(uint16_t port_id) {
  struct rte_flow_attr attr;
  struct rte_flow_item pattern[2] = {};
  struct rte_flow_action action[2] = {};
  struct rte_flow_error error;
  int retval;

  // Initialize the attributes to match on incoming packets
  memset(&attr, 0, sizeof(attr));
  attr.ingress = 1;  // Match on ingress packets

  // Define the action to drop the packet
  struct rte_flow_item_eth eth_spec;
  struct rte_flow_item_eth eth_mask;

  memset(&eth_spec, 0, sizeof(eth_spec));
  memset(&eth_mask, 0, sizeof(eth_mask));

  uint8_t mac[RTE_ETHER_ADDR_LEN];
  mac[0] = 0x10;
  mac[1] = 0x10;
  mac[2] = 0x10;
  mac[3] = 0x10;
  mac[4] = 0x10;
  mac[5] = 0x00;

  // Specify the source MAC address to match
  rte_memcpy(&eth_spec.src.addr_bytes, mac, RTE_ETHER_ADDR_LEN);
//   memset(&eth_mask.src.addr_bytes, 0xFF, RTE_ETHER_ADDR_LEN - 1);  // Full match on the source MAC

  pattern[0].type = RTE_FLOW_ITEM_TYPE_ETH;
  pattern[0].spec = &eth_spec;
  pattern[0].mask = &eth_mask;
  pattern[0].last = NULL;
  pattern[1].type = RTE_FLOW_ITEM_TYPE_END;

  action[0].type = RTE_FLOW_ACTION_TYPE_DROP;
  action[1].type = RTE_FLOW_ACTION_TYPE_END;

  // Validate the flow rule
  retval = rte_flow_validate(port_id, &attr, pattern, action, &error);
  if (retval != 0) {
    fprintf(stderr, "Error validating drop rule: %s\n", error.message);
    return -1;
  }

  // Create the flow rule
  struct rte_flow *flow = rte_flow_create(port_id, &attr, pattern, action, &error);
  if (!flow) {
    fprintf(stderr, "Error creating drop rule: %s\n", error.message);
    return -1;
  } else {
    printf("Created drop rule\n");
  }

  return 0;
}

// Function to create a flow rule for each source MAC address
static int create_mac_filter(uint16_t port_id, struct mac_to_queue_map *mac_map, size_t mac_map_size) {
    struct rte_flow_attr attr;
    struct rte_flow_item pattern[2] = {};
    struct rte_flow_action action[2] = {};
    struct rte_flow_error error;
    int retval;

    // Initialize the attributes to match on incoming packets
    memset(&attr, 0, sizeof(attr));
    attr.ingress = 1;  // Match on ingress packets

    for (size_t i = 0; i < mac_map_size; i++) {
        // Set up the match pattern for source MAC address
        struct rte_flow_item_eth eth_spec;
        struct rte_flow_item_eth eth_mask;

        memset(&eth_spec, 0, sizeof(eth_spec));
        memset(&eth_mask, 0, sizeof(eth_mask));

        // Specify the source MAC address to match
        rte_memcpy(&eth_spec.src.addr_bytes, mac_map[i].mac, RTE_ETHER_ADDR_LEN);
        memset(&eth_mask.src.addr_bytes, 0xFF, RTE_ETHER_ADDR_LEN);  // Full match on the source MAC

        pattern[0].type = RTE_FLOW_ITEM_TYPE_ETH;
        pattern[0].spec = &eth_spec;
        pattern[0].mask = &eth_mask;
        pattern[0].last = NULL;
        pattern[1].type = RTE_FLOW_ITEM_TYPE_END;

        // Define the action to direct the packet to a specific RX queue
        struct rte_flow_action_queue queue = {
            .index = mac_map[i].queue_id
        };

        action[0].type = RTE_FLOW_ACTION_TYPE_QUEUE;
        action[0].conf = &queue;
        action[1].type = RTE_FLOW_ACTION_TYPE_END;

        printf("Validaing flow rule for MAC %02X:%02X:%02X:%02X:%02X:%02X\n",
               mac_map[i].mac[0], mac_map[i].mac[1], mac_map[i].mac[2],
               mac_map[i].mac[3], mac_map[i].mac[4], mac_map[i].mac[5]);
        // Validate the flow rule
        retval = rte_flow_validate(port_id, &attr, pattern, action, &error);
        if (retval != 0) {
            fprintf(stderr, "Error validating flow rule for MAC %02X:%02X:%02X:%02X:%02X:%02X %s\n",
                    mac_map[i].mac[0], mac_map[i].mac[1], mac_map[i].mac[2],
                    mac_map[i].mac[3], mac_map[i].mac[4], mac_map[i].mac[5],
                    error.message);
            return -1;
        }

        // Create the flow rule
        struct rte_flow *flow = rte_flow_create(port_id, &attr, pattern, action, &error);
        if (!flow) {
            fprintf(stderr, "Error creating flow rule for MAC %02X:%02X:%02X:%02X:%02X:%02X: %s\n",
                    mac_map[i].mac[0], mac_map[i].mac[1], mac_map[i].mac[2],
                    mac_map[i].mac[3], mac_map[i].mac[4], mac_map[i].mac[5],
                    error.message);
            return -1; 
        } else {
            mac_map[i].flow = flow;  // Store the flow pointer
            printf("Created flow rule for MAC %02X:%02X:%02X:%02X:%02X:%02X directing to queue %d\n",
                   mac_map[i].mac[0], mac_map[i].mac[1], mac_map[i].mac[2],
                   mac_map[i].mac[3], mac_map[i].mac[4], mac_map[i].mac[5],
                   mac_map[i].queue_id);
        }
    }
    return 0;
}

// Function to destroy all flow rules created by create_mac_filter
static void destroy_mac_filter(uint16_t port_id, struct mac_to_queue_map *mac_map, size_t mac_map_size) {
    struct rte_flow_error error;

    for (size_t i = 0; i < mac_map_size; i++) {
        if (mac_map[i].flow) {
            printf("Destroying flow rule for MAC %02X:%02X:%02X:%02X:%02X:%02X\n",
                    mac_map[i].mac[0], mac_map[i].mac[1], mac_map[i].mac[2],
                    mac_map[i].mac[3], mac_map[i].mac[4], mac_map[i].mac[5]);
            int retval = rte_flow_destroy(port_id, mac_map[i].flow, &error);
            if (retval != 0) {
                fprintf(stderr, "Error destroying flow rule for MAC %02X:%02X:%02X:%02X:%02X:%02X: %s\n",
                        mac_map[i].mac[0], mac_map[i].mac[1], mac_map[i].mac[2],
                        mac_map[i].mac[3], mac_map[i].mac[4], mac_map[i].mac[5],
                        error.message);
            } else {
                mac_map[i].flow = NULL;  // Clear the flow pointer after destruction
            }
        }
    }
}

static int cleanup_all_rules(uint16_t port_id) {
    struct rte_flow_error error;
    int retval;

    // Flush all flow rules for the given port
    retval = rte_flow_flush(port_id, &error);
    if (retval != 0) {
        fprintf(stderr, "Error flushing rules on port %u: %s\n", port_id, error.message);
        return -1;
    } else {
        printf("All flow rules on port %u have been successfully removed.\n", port_id);
    }

    return 0;
}
