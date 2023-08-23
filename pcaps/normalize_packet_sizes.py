#!/usr/bin/env python3

import argparse
import time

from datetime import timedelta

from scapy.all import *
from scapy.utils import PcapWriter

from pathlib import Path

import utils

def generate_pkts(pcap_name: str, flows: dict, size: int):
	num_flows = len(flows)
	n_pkts = num_flows

	src_mac = utils.random_mac()
	dst_mac = utils.random_mac()

	encoded      = {}
	translations = {}

	# Bypassing scapy's awfully slow wrpcap, have to use raw packets as input
	# To get a raw packet from a scapy packet use `bytes_encode(pkt)`.
	with PcapWriter(pcap_name, linktype=DLT_EN10MB) as pkt_wr:
		for i, flow in enumerate(flows):
			flow_id = utils.get_flow_id(flow)

			if flow_id not in translations:
				utils.random

			if flow_id in encoded:
				raw_pkt = encoded[flow_id]
			else:
				pkt = Ether(src=src_mac, dst=dst_mac)
				pkt = pkt/IP(src=flow["src_ip"], dst=flow["dst_ip"])
				pkt = pkt/UDP(sport=flow["src_port"], dport=flow["dst_port"])

				crc_size      = 4
				overhead      = len(pkt) + crc_size
				payload_size  = size - overhead
				payload       = "\x00" * payload_size
				pkt          /= payload

				raw_pkt          = bytes_encode(pkt)
				encoded[flow_id] = raw_pkt

			if not pkt_wr.header_present:
				pkt_wr._write_header(raw_pkt)
			pkt_wr._write_packet(raw_pkt)

			print(f"\rGenerating packets ({100 * (i+1) / n_pkts:3.2f} %) ...", end="")
		print(" done")

def translate_flows(old_unique_flows, old_flows):
	new_unique_flows = utils.create_n_unique_flows(len(old_unique_flows))
	translator = { utils.get_flow_id(old): new for old, new in zip(old_unique_flows, new_unique_flows) }
	new_flows = [ translator[utils.get_flow_id(old)] for old in old_flows ]
	return new_flows

if __name__ == "__main__":
	start_time = time.time()

	parser = argparse.ArgumentParser(description='Generate a pcap with uniform traffic.\n')

	parser.add_argument('--input', help='Input trace', type=str, required=True)
	parser.add_argument('--output',  help='Output pcap', required=True)
	parser.add_argument('--size', help='Packet size ([64,1514])', type=int, required=True)
	parser.add_argument('--max', help='Grab at most {max} packets', type=int, default=-1, required=False)

	args = parser.parse_args()

	output = Path(args.output)
	output_dir = output.parent
	output_filename = output.name

	assert(Path(output_dir).exists())

	assert(Path(args.input).exists())
	unique_flows, flows, _ = utils.read_trace(args.input, max_packets=args.max)
	flows = translate_flows(unique_flows, flows)

	assert args.size >= 64 and args.size <= 1514

	generate_pkts(args.output, flows, args.size)

	elapsed = time.time() - start_time
	hr_elapsed = timedelta(seconds=elapsed)
	print(f"Execution time: {hr_elapsed}")
