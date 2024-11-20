#!/usr/bin/env python3

import math
import os
import re
import glob

from pathlib import Path
from statistics import mean, stdev, median

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
BENCH_DIR = Path(SCRIPT_DIR).parent / Path("bench")
BENCH_DIR_SCR = Path(SCRIPT_DIR).parent / Path("scr-nfs")

DAT_DIR = Path(SCRIPT_DIR) / Path("dats")

NF_NAMES = [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
PKT_SIZES = [ 64 ]

MD_SIZE_FOR_NFS = {
	"nop": 8,
	"pol": 16,
	"sbridge": 14,
	"fw": 25,
	"nat": 25,
	"psd": 19,
	"cl": 25
}

def technologies(nfs):
	data = {}

	for nf in nfs:
		with open(nf['infile']) as f:
			lines = f.readlines()
			lines = lines[1:] # skip first line
			
			parsed_data = []
			for line in lines:
				line = line.rstrip()
				line = line.split(',')

				line_data = [ int(d) if '.' not in d else float(d) for d in line ]
				parsed_data.append(line_data)

			cores = -1
			trimmed_data = []
			for d in parsed_data:
				_i = d[0]
				_cores = d[1]
				_gbps = d[2]
				_mpps = d[3]

				if _cores != cores:
					trimmed_data.append([])
					cores = _cores

				# cores, Gbps and Mpps
				trimmed_data[-1].append([ _cores, _gbps, _mpps ])

			nf_data_mpps = []
			nf_data_gbps = []
			nf_data_scr_gbps = []
			for d in trimmed_data:
				cores = d[0][0]

				# grabbing Gbps
				_median_gbps = median(x[1] for x in d)

				m_gbps = min(x[1] for x in d)
				M_gbps = max(x[1] for x in d)

				# grabbing Mpps
				_median_mpps = median(x[2] for x in d)

				m_mpps = min(x[2] for x in d)
				M_mpps = max(x[2] for x in d)

				# calculate real Gbps considering SCR overhead
				if (nf['scr']):
					# SCR overhead is in MD_SIZE_FOR_NFS for each NF
					_scr_overhead = MD_SIZE_FOR_NFS[nf['name']]
					_scr_gbps = _median_gbps - _scr_overhead * _median_mpps

					_scr_m_gbps = m_gbps - _scr_overhead * m_mpps
					_scr_M_gbps = M_gbps - _scr_overhead * M_gbps
					nf_data_scr_gbps.append((cores, _scr_gbps, _scr_m_gbps, _scr_M_gbps))

				nf_data_mpps.append((cores, _median_mpps, m_mpps, M_mpps))
				nf_data_gbps.append((cores, _median_gbps, m_gbps, M_gbps))
			
			base_mpps = [ e for e in nf_data_mpps if e[0] == 1  ]
			assert len(base_mpps) == 1, f"Expected 1 element, got {len(base_mpps)} for {nf['name']} ({nf['infile']})"
			base_perf_mpps = base_mpps[0][1]

			for i, d in enumerate(nf_data_mpps):
				speedup = d[1] / base_perf_mpps if base_perf_mpps > 0 else 1
				nf_data_mpps[i] = d + (speedup,)

			base_gbps = [ e for e in nf_data_gbps if e[0] == 1  ]
			assert len(base_gbps) == 1, f"Expected 1 element, got {len(base_gbps)} for {nf['name']} ({nf['infile']})"
			base_perf_gbps = base_gbps[0][1]

			for i, d in enumerate(nf_data_gbps):
				speedup = d[1] / base_perf_gbps if base_perf_gbps > 0 else 1
				nf_data_gbps[i] = d + (speedup,)

			if nf['scr']:
				base_scr_gbps = [ e for e in nf_data_scr_gbps if e[0] == 1  ]
				assert len(base_scr_gbps) == 1, f"Expected 1 element, got {len(base_scr_gbps)} for {nf['name']} ({nf['infile']})"
				base_perf_scr_gbps = base_scr_gbps[0][1]

				for i, d in enumerate(nf_data_scr_gbps):
					speedup = d[1] / base_perf_scr_gbps if base_perf_scr_gbps > 0 else 1
					nf_data_scr_gbps[i] = d + (speedup,)

		data[nf['name']] = (nf_data_mpps, nf_data_gbps, nf_data_scr_gbps)

	for nf in data:
		outfile_mpps = ''
		outfile_gbps = ''
		outfile_gbps_scr = ''
		for _nf in nfs:
			if _nf['name'] == nf:
				outfile_mpps = _nf['dat_mpps']
				outfile_gbps = _nf['dat_gbps']
				if _nf['scr']:
					outfile_gbps_scr = _nf['dat_gbps_scr']
				break
		assert(len(outfile_mpps))
		assert(len(outfile_gbps))

		with open(outfile_mpps, 'w') as o:
			o.write("#cores median min max speedup\n")
			for d in data[nf][0]:
				cores, _median, minimum, maximum, speedup = d
				o.write("{} {} {} {} {}\n".format(cores, _median, minimum, maximum, speedup))

		with open(outfile_gbps, 'w') as o:
			o.write("#cores median min max speedup\n")
			for d in data[nf][1]:
				cores, _median, minimum, maximum, speedup = d
				o.write("{} {} {} {} {}\n".format(cores, _median, minimum, maximum, speedup))

		if len(outfile_gbps_scr):
			with open(outfile_gbps_scr, 'w') as o:
				o.write("#cores median min max speedup\n")
				for d in data[nf][2]:
					cores, _median, minimum, maximum, speedup = d
					o.write("{} {} {} {} {}\n".format(cores, _median, minimum, maximum, speedup))

lut = [
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-uniform-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-uniform-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-uniform-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES 
		] + [
			{
				'name': f'locks-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-uniform-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-uniform-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-uniform-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'tm-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-uniform-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-uniform-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-uniform-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'rss-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-uniform-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-uniform-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-uniform-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'scr-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-uniform-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-uniform-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-uniform-{pkt_size}B_gbps.dat',
				'dat_gbps_scr': f'{DAT_DIR}/{nf}-scr-uniform-{pkt_size}B_gbps_scr.dat',
				'scr': True,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-single-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-single-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-single-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'locks-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-single-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-single-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-single-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'tm-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-single-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-single-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-single-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'rss-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-single-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-single-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-single-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'scr-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-single-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-single-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-single-{pkt_size}B_gbps.dat',
				'dat_gbps_scr': f'{DAT_DIR}/{nf}-scr-single-{pkt_size}B_gbps_scr.dat',
				'scr': True,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-zipf-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-zipf-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-zipf-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'locks-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-zipf-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-zipf-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-zipf-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'tm-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-zipf-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-zipf-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-zipf-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'rss-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-zipf-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-zipf-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-zipf-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'scr-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-zipf-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-zipf-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-zipf-{pkt_size}B_gbps.dat',
				'dat_gbps_scr': f'{DAT_DIR}/{nf}-scr-zipf-{pkt_size}B_gbps_scr.dat',
				'scr': True,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-imc-scr-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-imc-scr-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-imc-scr-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'locks-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-imc-scr-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-imc-scr-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-imc-scr-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'tm-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-imc-scr-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-imc-scr-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-imc-scr-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'rss-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-imc-scr-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-imc-scr-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-imc-scr-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'scr-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-imc-scr-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-imc-scr-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-imc-scr-{pkt_size}B_gbps.dat',
				'dat_gbps_scr': f'{DAT_DIR}/{nf}-scr-imc-scr-{pkt_size}B_gbps_scr.dat',
				'scr': True,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-caida-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-caida-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-caida-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'locks-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-caida-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-caida-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-caida-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'tm-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-caida-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-caida-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-caida-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'rss-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-caida-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-caida-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-caida-{pkt_size}B_gbps.dat',
				'scr': False,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		] + [
			{
				'name': f'scr-{nf}-{pkt_size}B',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-caida-{pkt_size}.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-caida-{pkt_size}B_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-caida-{pkt_size}B_gbps.dat',
				'dat_gbps_scr': f'{DAT_DIR}/{nf}-scr-caida-{pkt_size}B_gbps_scr.dat',
				'scr': True,
			} for nf in NF_NAMES for pkt_size in PKT_SIZES
		]
	},
]

def main():
	if not os.path.exists(DAT_DIR):
		os.mkdir(DAT_DIR)

	for entry in lut:
		# Filter out the ones which do not have data yet
		nfs = list(filter(lambda nf: os.path.exists(nf['infile']) , entry['nfs']))
		entry['processor'](nfs)
	
	print("Done processing raws data")

if __name__ == '__main__':
	main()
