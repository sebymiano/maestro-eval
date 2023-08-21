set terminal pdfcairo size 15, 10 enhanced color font 'Helvetica,45' linewidth 2
set output 'out/churn.pdf'

set tmargin 0
set bmargin 1

set multiplot layout 3,1 margins 0.12,0.95,.15,.95 spacing 0,0
# set multiplot layout 3,1 margins 0.12,0.95,.15,.95 spacing 0,0.05

set logscale x
set format x '{%g}M'
set xrange [ 0.0005 : 100 ] noreverse writeback

set ylabel "Mpps"
set ytics 20
set yrange [ 0 : 99 ] noreverse writeback
# set yrange [ 0 : 100 ] noreverse writeback

set grid ytics lt 0 lw 1 lc rgb "#404040"
set grid xtics mxtics lt 0 lw 1 lc rgb "#404040"

set linetype 1 linecolor rgb "#88CCEE"
set linetype 2 linecolor rgb "#44AA99"
set linetype 3 linecolor rgb "#117733"
set linetype 4 linecolor rgb "#332288"
set linetype 5 linecolor rgb "#DDCC77"
set linetype 6 linecolor rgb "#999933"
set linetype 7 linecolor rgb "#CC6677"
set linetype 8 linecolor rgb "#882255"
set linetype 9 linecolor rgb "#AA4499"
set linetype 10 linecolor rgb "#DDDDDD"

set linetype 1  lw 4 pt 1 ps 2
set linetype 2  lw 4 pt 2 ps 2
set linetype 3  lw 4 pt 3 ps 2
set linetype 4  lw 4 pt 4 ps 2
set linetype 5  lw 4 pt 5 ps 2
set linetype 6  lw 4 pt 6 ps 2
set linetype 7  lw 4 pt 7 ps 2
set linetype 8  lw 4 pt 8 ps 2
set linetype 9  lw 4 pt 9 ps 2
set linetype 10 lw 4 pt 10 ps 2

unset xlabel
unset xtics
unset x2tics
unset ylabel
unset key

set xtics (	\
			"" 0.001, "" 0.002 1, "" 0.003 1, "" 0.004 1, "" 0.005 1, "" 0.006 1, "" 0.007 1, "" 0.008 1, "" 0.009 1, \
			"" 0.01, "" 0.02 1, "" 0.03 1, "" 0.04 1, "" 0.05 1, "" 0.06 1, "" 0.07 1, "" 0.08 1, "" 0.09 1, \
			"" 0.1, "" 0.2 1, "" 0.3 1, "" 0.4 1, "" 0.5 1, "" 0.6 1, "" 0.7 1, "" 0.8 1, "" 0.9 1, \
			"" 1,   "" 2 1, "" 3 1, "" 4 1, "" 5 1, "" 6 1, "" 7 1, "" 8 1, "" 9 1, \
			"" 10, 	"" 20 1, "" 30 1, "" 40 1, "" 50 1, "" 60 1, "" 70 1, "" 80 1, "" 90 1, \
			"" 100, "" 200 1, "" 300 1, "" 400 1, "" 500 1, "" 600 1, "" 700 1, "" 800 1, "" 900 1, \
		)
set xtics nomirror

set y2label "SN" font ',45'
plot "./dats/churn-sn-fw_cores_1.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 1 t "1 core", \
	'' using ($5/1000000):3 with lines lt 1 notitle, \
	"./dats/churn-sn-fw_cores_2.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 2 t "2 cores", \
	'' using ($5/1000000):3 with lines lt 2 notitle, \
	"./dats/churn-sn-fw_cores_4.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 3 t "4 cores", \
	'' using ($5/1000000):3 with lines lt 3 notitle, \
	"./dats/churn-sn-fw_cores_6.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 4 t "6 cores", \
	'' using ($5/1000000):3 with lines lt 4 notitle, \
	"./dats/churn-sn-fw_cores_8.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 5 t "8 cores", \
	'' using ($5/1000000):3 with lines lt 5 notitle, \
	"./dats/churn-sn-fw_cores_10.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 6 t "10 cores", \
	'' using ($5/1000000):3 with lines lt 6 notitle, \
	"./dats/churn-sn-fw_cores_12.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 7 t "12 cores", \
	'' using ($5/1000000):3 with lines lt 7 notitle, \
	"./dats/churn-sn-fw_cores_14.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 8 t "14 cores", \
	'' using ($5/1000000):3 with lines lt 8 notitle, \
	"./dats/churn-sn-fw_cores_16.dat" using ($5/1000000):3:($6/1000000):2 w xyerrorbars lt 9 t "16 cores", \
	'' using ($5/1000000):3 with lines lt 9 notitle

set ylabel "Mpps"

set y2label "Locks" font ',45'
plot "./dats/churn-locks-fw_cores_1.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 1 t "1 core", \
	'' using ($5/1000000):3 with lines lt 1 notitle, \
	"./dats/churn-locks-fw_cores_2.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 2 t "2 cores", \
	'' using ($5/1000000):3 with lines lt 2 notitle, \
	"./dats/churn-locks-fw_cores_4.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 3 t "4 cores", \
	'' using ($5/1000000):3 with lines lt 3 notitle, \
	"./dats/churn-locks-fw_cores_6.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 4 t "6 cores", \
	'' using ($5/1000000):3 with lines lt 4 notitle, \
	"./dats/churn-locks-fw_cores_8.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 5 t "8 cores", \
	'' using ($5/1000000):3 with lines lt 5 notitle, \
	"./dats/churn-locks-fw_cores_10.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 6 t "10 cores", \
	'' using ($5/1000000):3 with lines lt 6 notitle, \
	"./dats/churn-locks-fw_cores_12.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 7 t "12 cores", \
	'' using ($5/1000000):3 with lines lt 7 notitle, \
	"./dats/churn-locks-fw_cores_14.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 8 t "14 cores", \
	'' using ($5/1000000):3 with lines lt 8 notitle, \
	"./dats/churn-locks-fw_cores_16.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 9 t "16 cores", \
	'' using ($5/1000000):3 with lines lt 9 notitle

unset x2tics
unset x2label
unset ylabel

set xlabel "Churn (fpm)"
set xtics (	\
			"0" 0.0005, \
			"1k" 0.001, "" 0.002 1, "" 0.003 1, "" 0.004 1, "" 0.005 1, "" 0.006 1, "" 0.007 1, "" 0.008 1, "" 0.009 1, \
			"10k" 0.01, "" 0.02 1, "" 0.03 1, "" 0.04 1, "" 0.05 1, "" 0.06 1, "" 0.07 1, "" 0.08 1, "" 0.09 1, \
			"100k" 0.1, "" 0.2 1, "" 0.3 1, "" 0.4 1, "" 0.5 1, "" 0.6 1, "" 0.7 1, "" 0.8 1, "" 0.9 1, \
			"1M" 1,   	"" 2 1, "" 3 1, "" 4 1, "" 5 1, "" 6 1, "" 7 1, "" 8 1, "" 9 1, \
			"10M" 10, 	"" 20 1, "" 30 1, "" 40 1, "" 50 1, "" 60 1, "" 70 1, "" 80 1, "" 90 1, \
			"100M" 100, "" 200 1, "" 300 1, "" 400 1, "" 500 1, "" 600 1, "" 700 1, "" 800 1, "" 900 1, \
		)
set xtics nomirror

set key at 90, 80
set key box vertical width 2 height 1 spacing 1 font ",30"

set y2label "TM" font ',45'
plot "./dats/churn-tm-fw_cores_1.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 1 t "1 core", \
	'' using ($5/1000000):3 with lines lt 1 notitle, \
	"./dats/churn-tm-fw_cores_2.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 2 t "2 cores", \
	'' using ($5/1000000):3 with lines lt 2 notitle, \
	"./dats/churn-tm-fw_cores_4.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 3 t "4 cores", \
	'' using ($5/1000000):3 with lines lt 3 notitle, \
	"./dats/churn-tm-fw_cores_6.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 4 t "6 cores", \
	'' using ($5/1000000):3 with lines lt 4 notitle, \
	"./dats/churn-tm-fw_cores_8.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 5 t "8 cores", \
	'' using ($5/1000000):3 with lines lt 5 notitle, \
	"./dats/churn-tm-fw_cores_10.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 6 t "10 cores", \
	'' using ($5/1000000):3 with lines lt 6 notitle, \
	"./dats/churn-tm-fw_cores_12.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 7 t "12 cores", \
	'' using ($5/1000000):3 with lines lt 7 notitle, \
	"./dats/churn-tm-fw_cores_14.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 8 t "14 cores", \
	'' using ($5/1000000):3 with lines lt 8 notitle, \
	"./dats/churn-tm-fw_cores_16.dat" using ($5/1000000):3:($6/1000000):4 w xyerrorbars lt 9 t "16 cores", \
	'' using ($5/1000000):3 with lines lt 9 notitle