set terminal pdf size 9, 3 enhanced color font 'Helvetica,30' linewidth 2
set output 'out/latency-sn.pdf'

set key bottom right

set xlabel "Latency ({/Symbol m}s)"

set ylabel "CDF"
set ytics 0.5
set yrange [ 0 : 1 ] noreverse writeback

set grid ytics lt 0 lw 1 lc rgb "#bbbbbb"
set grid xtics lt 0 lw 1 lc rgb "#bbbbbb"

set linetype 1 linecolor rgb "#332288" lw 3
set linetype 2 linecolor rgb "#CC6677" lw 3
set linetype 3 linecolor rgb "#88CCEE" lw 3

plot "./dats/latency-fw-sn-1-cores.dat" with lines title "1 core" lt 1, \
    "./dats/latency-fw-sn-16-cores.dat" with lines title "16 cores" lt 2 \
