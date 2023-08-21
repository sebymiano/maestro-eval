set terminal pdf size 16, 4 enhanced color font 'Helvetica,45' linewidth 3
set output 'out/time_to_generate.pdf'

set xlabel "NFs"

set xrange [ -0.5:8.5 ]

set ylabel "Time (min)"
set ytics 4
set yrange [ 0 : * ] noreverse writeback

set style data histogram

set style histogram clustered gap 5 title textcolor lt -1
set style histogram clustered errorbars gap 3 lw 1

set style fill solid border 0
# set style fill pattern 1

set boxwidth 0.6

set grid ytics lw 1 lc rgb "#000000"

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

unset colorbox

set palette defined ( \
	0 "#88CCEE", \
	1 "#44AA99", \
	2 "#117733", \
	3 "#332288", \
	4 "#DDCC77", \
	5 "#999933", \
	6 "#CC6677", \
	7 "#AA4499", \
	8 "#882255" \
)

plot "./dats/time_to_generate_histogram.dat" using 0:($2/60):($3/60):4:xtic(1) w boxerrorbars lc palette notitle, \
	'' using 0:($2/60+1.5):(sprintf("%1.1f",($2/60))) with labels notitle
