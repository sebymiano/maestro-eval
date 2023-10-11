set terminal pdf size 16, 4 enhanced color font 'Helvetica,40' linewidth 2
set output 'out/skew.pdf'

set key horiz
set key reverse outside top center Left enhanced spacing 1

set xlabel "Number of cores"

set xtics border in scale 0,0 nomirror autojustify
set xtics norangelimit 
set xtics ()

set ylabel "Mpps"
set yrange [ 0 : 100 ] noreverse writeback

set style data histogram
set style histogram clustered gap 1 title textcolor lt -1

set style fill solid border 0

set boxwidth 1
set style histogram errorbars lw 2

set grid ytics lw 1 lc rgb "#000000"

set linetype 1 linecolor rgb "#332288"
set linetype 2 linecolor rgb "#CC6677"
set linetype 3 linecolor rgb "#88CCEE"

plot \
	"./dats/skew-fw-uniform.dat" using 2:3:4:xtic(1) w histogram t "Uniform", \
	"./dats/skew-fw-zipf.dat" using 2:3:4:xtic(1) w histogram t "Zipf", \
	"./dats/skew-fw-zipf-balanced.dat" using 2:3:4:xtic(1) w histogram t "Zipf (balanced)"