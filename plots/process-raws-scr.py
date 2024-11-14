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

		data[nf['name']] = (nf_data_mpps, nf_data_gbps)

	for nf in data:
		outfile_mpps = ''
		outfile_gbps = ''
		for _nf in nfs:
			if _nf['name'] == nf:
				outfile_mpps = _nf['dat_mpps']
				outfile_gbps = _nf['dat_gbps']
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

lut = [
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-uniform.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-uniform_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-uniform_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-uniform.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-uniform_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-uniform_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-uniform.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-uniform_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-uniform_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-uniform.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-uniform_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-uniform_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-uniform.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-uniform_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-uniform_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-single.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-single_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-single_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-single.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-single_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-single_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-single.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-single_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-single_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-single.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-single_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-single_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-single.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-single_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-single_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-zipf.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-zipf_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-zipf_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-zipf.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-zipf_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-zipf_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-zipf.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-zipf_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-zipf_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-zipf.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-zipf_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-zipf_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-zipf.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-zipf_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-zipf_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-imc-scr.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-imc-scr_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-imc-scr_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-imc-scr.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-imc-scr_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-imc-scr_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-imc-scr.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-imc-scr_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-imc-scr_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-imc-scr.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-imc-scr_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-imc-scr_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-imc-scr.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-imc-scr_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-imc-scr_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-caida.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-sn-caida_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-sn-caida_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-caida.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-locks-caida_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-locks-caida_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-caida.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-tm-caida_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-tm-caida_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-caida.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-rss-caida_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-rss-caida_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/{nf}-scr-caida.csv',
				'dat_mpps': f'{DAT_DIR}/{nf}-scr-caida_mpps.dat',
				'dat_gbps': f'{DAT_DIR}/{nf}-scr-caida_gbps.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
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
