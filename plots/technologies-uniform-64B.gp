set terminal pdf size 18, 24 enhanced color font 'Helvetica,45' linewidth 2
set output 'out/technologies-uniform-64B.pdf'

set tmargin 0
set bmargin 1

set multiplot layout 9,1 margins 0.1,0.95,.1,.97 spacing 0,0

set key horiz
set key reverse outside top center Left enhanced spacing 1

set style data histogram
set style histogram clustered gap 1 title textcolor lt -1

set style fill solid border 0

set boxwidth 1
set style histogram errorbars lw 2

set xtics border in scale 0,0 nomirror autojustify
set xtics norangelimit

set grid ytics lw 1 lc rgb "#000000"

set linetype 1 linecolor rgb "#332288"
set linetype 2 linecolor rgb "#CC6677"
set linetype 3 linecolor rgb "#88CCEE"

unset xtics
unset x2tics

set ytics 20
# set yrange [ 0 : 100 ] noreverse writeback
set yrange [ 0 : 99 ] noreverse writeback
set samples 16

set ylabel " "
set y2label "NOP" font ',55'
plot "<(sed -n '1,16p' ./dats/nop-sn.dat)" using 2:3:4:xtic(1) w histogram t "Shared-nothing", \
	 "./dats/nop-locks.dat" using 2:3:4:xtic(1) w histogram t "Lock-based", \
	 "./dats/nop-tm.dat" using 2:3:4:xtic(1) w histogram t "TM"

set ylabel " "
set y2label "SBridge" font ',55'
plot "<(sed -n '1,16p' ./dats/sbridge-sn.dat)" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/sbridge-locks.dat" using 2:3:4:xtic(1) w histogram fs  notitle, \
	 "./dats/sbridge-tm.dat" using 2:3:4:xtic(1) w histogram fs notitle

set ylabel " "
set y2label "DBridge" font ',55'
plot "./dats/bridge-locks.dat" using 2:3:4:xtic(1) lt 2 w histogram fs  notitle, \
	 "./dats/bridge-tm.dat" using 2:3:4:xtic(1) lt 3 w histogram fs notitle

set ylabel " "
set y2label "Policer" font ',55'
plot "<(sed -n '1,16p' ./dats/pol-sn.dat)" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/pol-locks.dat" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/pol-tm.dat" using 2:3:4:xtic(1) w histogram fs notitle

set ylabel "Throughput (Mpps)"
set y2label "FW" font ',55'
plot "<(sed -n '1,16p' ./dats/fw-sn.dat)" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/fw-locks.dat" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/fw-tm.dat" using 2:3:4:xtic(1) w histogram fs notitle

set ylabel " "
set y2label "NAT" font ',55'
plot "<(sed -n '1,16p' ./dats/nat-sn.dat)" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/nat-locks.dat" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/nat-tm.dat" using 2:3:4:xtic(1) w histogram fs notitle

set ylabel " "
set y2label "CL" font ',55'
plot "<(sed -n '1,16p' ./dats/cl-sn.dat)" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/cl-locks.dat" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/cl-tm.dat" using 2:3:4:xtic(1) w histogram fs notitle

set ylabel " "
set y2label "PSD" font ',55'
plot "<(sed -n '1,16p' ./dats/psd-sn.dat)" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/psd-locks.dat" using 2:3:4:xtic(1) w histogram fs notitle, \
	 "./dats/psd-tm.dat" using 2:3:4:xtic(1) w histogram fs notitle

set tic scale 0
set xtics ()

set ylabel " "
set y2label "LB" font ',55'
set xlabel "Number of cores" font ',55'
plot "./dats/lb-locks.dat" using 2:3:4:xtic(1) lt 2 w histogram fs notitle, \
	 "./dats/lb-tm.dat" using 2:3:4:xtic(1) lt 3 w histogram fs notitle

unset multiplot
unset key
unset xrange
