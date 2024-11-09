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

			nf_data = []
			for d in trimmed_data:
				cores = d[0][0]

				# grabbing Gbps
				# _median = median(x[1] for x in d)

				# m = min(x[1] for x in d)
				# M = max(x[1] for x in d)

				# grabbing Mpps
				_median = median(x[2] for x in d)

				m = min(x[2] for x in d)
				M = max(x[2] for x in d)

				nf_data.append((cores, _median, m, M))
			
			base = [ e for e in nf_data if e[0] == 1  ]
			assert len(base) == 1
			base_perf_mpps = base[0][1]

			for i, d in enumerate(nf_data):
				speedup = d[1] / base_perf_mpps if base_perf_mpps > 0 else 1
				nf_data[i] = d + (speedup,)

		data[nf['name']] = nf_data

	for nf in data:
		outfile = ''
		for _nf in nfs:
			if _nf['name'] == nf:
				outfile = _nf['dat']
				break
		assert(len(outfile))

		with open(outfile, 'w') as o:
			for d in data[nf]:
				cores, _median, minimum, maximum, speedup = d
				o.write("{} {} {} {} {}\n".format(cores, _median, minimum, maximum, speedup))

lut = [
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-uniform.csv',
				'dat': f'{DAT_DIR}/{nf}-sn-uniform.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-uniform.csv',
				'dat': f'{DAT_DIR}/{nf}-locks-uniform.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-uniform.csv',
				'dat': f'{DAT_DIR}/{nf}-tm-uniform.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-uniform.csv',
				'dat': f'{DAT_DIR}/{nf}-rss-uniform.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/technologies/{nf}-scr-uniform.csv',
				'dat': f'{DAT_DIR}/{nf}-scr-uniform.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-single.csv',
				'dat': f'{DAT_DIR}/{nf}-sn-single.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-single.csv',
				'dat': f'{DAT_DIR}/{nf}-locks-single.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-single.csv',
				'dat': f'{DAT_DIR}/{nf}-tm-single.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-single.csv',
				'dat': f'{DAT_DIR}/{nf}-rss-single.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/technologies/{nf}-scr-single.csv',
				'dat': f'{DAT_DIR}/{nf}-scr-single.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-zipf.csv',
				'dat': f'{DAT_DIR}/{nf}-sn-zipf.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-zipf.csv',
				'dat': f'{DAT_DIR}/{nf}-locks-zipf.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-zipf.csv',
				'dat': f'{DAT_DIR}/{nf}-tm-zipf.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-zipf.csv',
				'dat': f'{DAT_DIR}/{nf}-rss-zipf.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/technologies/{nf}-scr-zipf.csv',
				'dat': f'{DAT_DIR}/{nf}-scr-zipf.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		]
	},
	{
		'processor': technologies,
		'nfs': [
			{
				'name': f'shared-nothing-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-sn-imc-scr.csv',
				'dat': f'{DAT_DIR}/{nf}-sn-imc-scr.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'locks-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-locks-imc-scr.csv',
				'dat': f'{DAT_DIR}/{nf}-locks-imc-scr.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'tm-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-tm-imc-scr.csv',
				'dat': f'{DAT_DIR}/{nf}-tm-imc-scr.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'rss-{nf}',
				'infile': f'{BENCH_DIR}/technologies/{nf}-rss-imc-scr.csv',
				'dat': f'{DAT_DIR}/{nf}-rss-imc-scr.dat',
			} for nf in [ 'nop', 'pol', 'sbridge', 'fw', 'nat', 'psd', 'cl' ]
		] + [
			{
				'name': f'scr-{nf}',
				'infile': f'{BENCH_DIR_SCR}/technologies/{nf}-scr-imc-scr.csv',
				'dat': f'{DAT_DIR}/{nf}-scr-imc-scr.dat',
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

if __name__ == '__main__':
	main()
