set terminal pdf size 16, 4 enhanced color font 'Helvetica,40' linewidth 2
set output 'out/packet-size.pdf'

set key horiz
set key reverse outside top center Left enhanced spacing 1

set xlabel "Packet size (bytes)"
# set xlabel "Packet size (bytes)" offset 0,-0.6

set xtics border in scale 0,0 nomirror autojustify
set xtics norangelimit 
set xtics ()

set ylabel "Gbps" textcolor rgb "#332288" offset 1,0
set ytics 20 nomirror textcolor rgb "#332288"
set yrange [ 0 : 100 ] noreverse writeback

set y2label "Mpps" textcolor rgb "#CC6677" offset -1,0
set y2tics nomirror textcolor rgb "#CC6677"
set y2range [ 0 : * ] noreverse writeback
set link y

# set label "Internet\ntraffic" at 2.3,93 center font "Helvetica-Bold,22"
# set arrow from 2.4,75 to 2.7,60 filled size screen 0.015,20,100

set style data histogram

set style histogram clustered title textcolor lt -1
set style histogram errorbars gap 1 lw 1
# set boxwidth 5

set style fill solid border 0
# set style fill pattern 1

set boxwidth 1

set grid ytics lw 1 lc rgb "#000000"

set linetype 1 linecolor rgb "#332288"
set linetype 2 linecolor rgb "#CC6677"
set linetype 8 linecolor rgb "#882255"
set linetype 9 linecolor rgb "#AA4499"
set linetype 10 linecolor rgb "#DDDDDD"

plot "./dats/packet-size.dat" using 2:3:xtic(1) w histogram axes x1y1 fs notitle, \
	"./dats/packet-size.dat" using 4:5:xtic(1) w histogram axes x1y2 fs notitle
