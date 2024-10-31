import socket
import ipaddress
from scapy.all import *
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, TCP, UDP
from scapy.utils import wrpcap
import argparse
import os
import tqdm


class MetadataElem:
    def __init__(self, protocol=0):
        self.protocol = protocol

    def __str__(self):
        # Convert the MAC address from integer to a human-readable MAC format
        proto = self.protocol
        return f"Protocol: {proto}\n"

    def __bytes__(self):
        # Convert MAC address to bytes (6 bytes for MAC address in big-endian)
        return self.protocol.to_bytes(1, "big")


# Generator function to read and yield packets one by one
def read_packets(pcap_file):
    with PcapReader(pcap_file) as pcap_reader:
        for packet_number, packet in enumerate(pcap_reader, start=0):
            yield packet_number, packet


def modify_pkt_size(pkt, pkt_len):
    payload_len = pkt_len - len(pkt)
    if payload_len <= 0:
        return pkt
    payload_data = b"X" * payload_len
    new_pkt = pkt / Raw(load=payload_data)
    return new_pkt


def get_md_from_pkt(pkt):
    md_elem = MetadataElem()

    if pkt.haslayer(TCP):
        md_elem.protocol = socket.IPPROTO_TCP
    elif pkt.haslayer(UDP):
        md_elem.protocol = socket.IPPROTO_UDP
    else:
        print(f"[gen_pcap_with_md_nop] Unsupported layer type: {pkt.getlayer(IP).proto}")
        sys.exit(1)

    return md_elem


def gen_pcap_with_md_nop(num_cores, dst_mac, output_path, input_file, pkt_len, overwrite=False):
    print(f"[gen_pcap_with_md_nop] start num_cores: {num_cores}")

    if not os.path.exists(output_path):
        os.makedirs(output_path)

    output_file = f"{output_path}/dpdk_nop_scr_{num_cores}cores.pcap"

    if os.path.exists(output_file):
        if overwrite:  # If overwrite is enabled, delete the existing file
            os.remove(output_file)
        else:
            print(f"[gen_pcap_with_md_nop] Output file {output_file} already exists. Exiting.")
            return
    append_flag = False
    # input_pkts = rdpcap(input_file)
    new_pkts = list()
    md_initial = MetadataElem()
    pkt_history = []
    if num_cores > 1:
        pkt_history = [md_initial] * (num_cores - 1)

    command = f'capinfos {input_file} | grep "Number of packets" | tr -d " " | grep -oP "Numberofpackets=\K\d+"'
    output = subprocess.check_output(command, shell=True, universal_newlines=True)
    total_packets = int(output.strip())
    # Get the total number of packets for the progress bar
    # total_packets = sum(1 for _ in read_packets(input_file))
    print(f"[gen_pcap_with_md_nop] Total packets in {input_file}: {total_packets}")

    with PcapWriter(output_file, linktype=DLT_EN10MB) as pkt_wr:
        for i, curr_pkt in read_packets(input_file):
            # get metadata from curr_pkt
            md_bytes = b""
            for x in pkt_history:
                md_bytes += bytes(x)
            # src_mac is used for rss
            src_mac = f"10:10:10:10:10:{format(i % num_cores, '02x')}"

            new_pkt = (
                Ether(dst=dst_mac, src=src_mac, type=ETH_P_IP) / md_bytes / curr_pkt
            )
            new_pkt = modify_pkt_size(new_pkt, pkt_len)
            new_pkts.append(new_pkt)

            if num_cores > 1:
                curr_md = get_md_from_pkt(curr_pkt)
                # update pkt_history
                pkt_history = pkt_history[1:]
                pkt_history.append(curr_md)

            raw_pkt = bytes_encode(new_pkt)
            if not pkt_wr.header_present:
                pkt_wr.write_header(raw_pkt)
            pkt_wr.write_packet(raw_pkt)

            print(f"\r[gen_pcap_with_md_nop] Generating {output_file} ({100 * (i+1) / total_packets:3.2f} %) ...", end="")

    print("")
    print(f"[gen_pcap_with_md_nop] output pcap: {output_file}")
    print("[gen_pcap_with_md_nop] Done!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Information about parameters")
    parser.add_argument(
        "--input", "-i", dest="input_file", help="Input file name", required=True
    )
    parser.add_argument(
        "--output", "-o", dest="output_path", help="Output file name", required=True
    )
    parser.add_argument(
        "--num_cores",
        "-n",
        dest="num_cores",
        help="Number of cores used to process packets",
        type=int,
        default=1,
    )
    parser.add_argument(
        "--dst_mac",
        "-d",
        dest="dst_mac",
        help="Destination MAC address to use in the generated PCAP file",
        default="00:00:00:00:00:02",
    )
    parser.add_argument(
        "--pkt_len", dest="pkt_len", help="Pkt len", type=int, default=64
    )
    parser.add_argument(
        "--overwrite",
        dest="overwrite",
        help="Overwrite existing output file",
        action="store_true",
    )

    args = parser.parse_args()
    dst_mac = args.dst_mac

    gen_pcap_with_md_nop(
        args.num_cores, dst_mac, args.output_path, args.input_file, args.pkt_len, args.overwrite
    )
