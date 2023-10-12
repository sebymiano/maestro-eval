set terminal pdf size 16, 4 enhanced color font 'Helvetica,40' linewidth 2
set output 'out/vpp.pdf'

set key horiz
set key reverse outside top center Left enhanced spacing 1

set xlabel "Number of cores"

set xtics border in scale 0,0 nomirror autojustify
set xtics norangelimit 
set xtics ()

set yrange [ 0 : 100 ] noreverse writeback

set style data histogram
set style histogram clustered gap 1 title textcolor lt -1
set style histogram errorbars gap 1 lw 1
set style fill solid border 0

set boxwidth 1

set grid ytics lw 1 lc rgb "#000000"

set linetype 1 linecolor rgb "#332288"
set linetype 2 linecolor rgb "#CC6677"
set linetype 8 linecolor rgb "#882255"
set linetype 9 linecolor rgb "#AA4499"
set linetype 10 linecolor rgb "#DDDDDD"

set ylabel "Mpps"
set ytics 20

plot "./dats/nat-maestro-sn.dat" using 4:5:xtic(1) w histogram fs t "Maestro (SN)", \
	"./dats/nat-maestro-locks.dat" using 4:5:xtic(1) w histogram fs t "Maestro (Locks)", \
	"./dats/nat-vpp.dat" using 4:5:xtic(1) w histogram fs t "VPP"
