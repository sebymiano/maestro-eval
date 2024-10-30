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
    def __init__(self):
        self.ether_type = 0
        self.packet_len = 0
        self.src_port = 0
        self.dst_port = 0
        self.src_addr = 0
        self.dst_addr = 0
        self.protocol = 0

    def __str__(self):
        out = ""
        out += f"Ether type: {self.ether_type}\n"
        out += f"Packet len: {self.packet_len}\n"
        out += f"Source port: {self.src_port}\n"
        out += f"Dest port: {self.dst_port}\n"
        out += f"Source IP: {ipaddress.IPv4Address(self.src_ip)}\n"
        out += f"Dest IP: {ipaddress.IPv4Address(self.dst_ip)}\n"
        out += f"Protocol: {self.protocol}\n"
        return out

    def __bytes__(self):
        md_bytes = b""
        md_bytes += self.ether_type.to_bytes(2, "big")
        md_bytes += self.packet_len.to_bytes(2, "big")
        md_bytes += self.src_port.to_bytes(2, "big")
        md_bytes += self.dst_port.to_bytes(2, "big")
        md_bytes += self.src_addr.to_bytes(4, "big")
        md_bytes += self.dst_addr.to_bytes(4, "big")
        md_bytes += self.protocol.to_bytes(1, "big")
        return md_bytes


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

    md_elem.src_addr = int(ipaddress.ip_address(pkt.getlayer(IP).src))
    md_elem.dst_addr = int(ipaddress.ip_address(pkt.getlayer(IP).dst))
    if pkt.haslayer(TCP):
        md_elem.protocol = socket.IPPROTO_TCP
        md_elem.src_port = pkt.getlayer(TCP).sport
        md_elem.dst_port = pkt.getlayer(TCP).dport
    elif pkt.haslayer(UDP):
        md_elem.protocol = socket.IPPROTO_UDP
        md_elem.src_port = pkt.getlayer(UDP).sport
        md_elem.dst_port = pkt.getlayer(UDP).dport
    else:
        print(f"[gen_pcap_with_md_cl] Unsupported layer type: {pkt.getlayer(IP).proto}")
        sys.exit(1)

    md_elem.packet_len = len(pkt)
    md_elem.ether_type = pkt.getlayer(Ether).type
    # print(md_elem)
    return md_elem


def gen_pcap_with_md_cl(num_cores, dst_mac, output_path, input_file, pkt_len):
    print(f"[gen_pcap_with_md_cl] start num_cores: {num_cores}")

    if not os.path.exists(output_path):
        os.makedirs(output_path)

    output_file = f"{output_path}/dpdk_cl_scr_{num_cores}cores.pcap"
    append_flag = False
    # input_pkts = rdpcap(input_file)
    new_pkts = list()
    md_initial = MetadataElem()
    pkt_history = []
    if num_cores > 1:
        pkt_history = [md_initial] * (num_cores - 1)

    # Get the total number of packets for the progress bar
    total_packets = sum(1 for _ in read_packets(input_file))
    print(f"[gen_pcap_with_md_cl] Total packets in {input_file}: {total_packets}")

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

            print(f"\r[gen_pcap_with_md_cl] Generating {output_file} ({100 * (i+1) / total_packets:3.2f} %) ...", end="")

            # if len(new_pkts) >= PKTS_WRITE_MAX_NUM:
            #     wrpcap(output_file, new_pkts, append=append_flag)
            #     # print(f"Written {len(new_pkts)} packets to {output_pcap}")
            #     new_pkts = []
            #     append_flag = True
    # if new_pkts:
    #     wrpcap(output_file, new_pkts, append=append_flag)
    print("")
    print(f"[gen_pcap_with_md_cl] output pcap: {output_file}")
    print("[gen_pcap_with_md_cl] Done!")


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

    args = parser.parse_args()
    dst_mac = args.dst_mac

    gen_pcap_with_md_cl(
        args.num_cores, dst_mac, args.output_path, args.input_file, args.pkt_len
    )
