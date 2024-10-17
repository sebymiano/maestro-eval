#!/usr/bin/env python3

import argparse
import time

from datetime import timedelta

from scapy.all import *
from scapy.utils import PcapWriter

from pathlib import Path
from typing import Union

import utils

def generate_pkts(pcap_name: str, flows: dict, size: Union[list[int],int]):
	num_flows = len(flows)

	if isinstance(size, int):
		n_pkts = num_flows
		sizes  = [ size ] * n_pkts
	else:
		n_pkts = len(size)
		sizes  = size
	
	assert len(sizes) == n_pkts

	src_mac = utils.random_mac()
	dst_mac = utils.random_mac()

	encoded = {}

	# Bypassing scapy's awfully slow wrpcap, have to use raw packets as input
	# To get a raw packet from a scapy packet use `bytes_encode(pkt)`.
	with PcapWriter(pcap_name, linktype=DLT_EN10MB) as pkt_wr:
		for i, pkt_size in enumerate(sizes):
			flow       = flows[i % num_flows]
			flow_id    = utils.get_flow_id(flow)
			encoded_id = (flow_id,pkt_size)

			if encoded_id in encoded:
				raw_pkt = encoded[encoded_id]
			else:
				pkt = Ether(src=src_mac, dst=dst_mac)
				pkt = pkt/IP(src=flow["src_ip"], dst=flow["dst_ip"])
				pkt = pkt/UDP(sport=flow["src_port"], dport=flow["dst_port"])

				crc_size      = 4
				overhead      = len(pkt) + crc_size
				payload_size  = pkt_size - overhead
				payload       = "\x00" * payload_size
				pkt          /= payload

				raw_pkt             = bytes_encode(pkt)
				encoded[encoded_id] = raw_pkt

			if not pkt_wr.header_present:
				pkt_wr.write_header(raw_pkt)
			pkt_wr.write_packet(raw_pkt)

			print(f"\rGenerating {pcap_name} ({100 * (i+1) / n_pkts:3.2f} %) ...", end="")
		print(" done")

if __name__ == "__main__":
	start_time = time.time()

	parser = argparse.ArgumentParser(description='Generate a pcap with uniform traffic.\n')

	parser.add_argument('--output',  help='output pcap', required=True)
	parser.add_argument('--flows', help='number of unique flows (> 0)', type=int, required=True)
	parser.add_argument('--size', help='packet size ([64,1514])', type=int, required=False)
	parser.add_argument('--pcap', help='Trace from which to base packet size distribution', type=str, default=None, required=False)
	parser.add_argument('--max', help='Grab at most {max} packets', type=int, default=-1, required=False)
	parser.add_argument('--private-only', help='generate only flows on private networks', action='store_true', required=False)
	parser.add_argument('--internet-only', help='generate Internet only IPs', action='store_true', required=False)

	args = parser.parse_args()

	output = Path(args.output)
	output_dir = output.parent
	output_filename = output.name

	assert(Path(output_dir).exists())
	assert args.flows > 0

	if args.pcap != None:
		assert(Path(args.pcap).exists())
		_, _, pkt_sizes = utils.read_trace(args.pcap, args.max)
		num_flows = args.flows
	else:
		if args.size == None:
			print("Error: if --pcap is not used, then --size is required.")
			exit(1)

		assert args.size >= 64 and args.size <= 1514

		num_flows = args.flows
		pkt_sizes = args.size

	flows = utils.create_n_unique_flows(num_flows, args.private_only, args.internet_only)
	generate_pkts(args.output, flows, pkt_sizes)

	elapsed = time.time() - start_time
	hr_elapsed = timedelta(seconds=elapsed)
	print(f"Execution time: {hr_elapsed}")
