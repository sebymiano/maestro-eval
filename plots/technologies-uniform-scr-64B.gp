set terminal pdf size 18, 24 enhanced color font 'Helvetica,45' linewidth 2
set output 'out/technologies-uniform-scr-64B.pdf'

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

# Define linetypes for each technology
set linetype 1 linecolor rgb "#332288"  # Shared-nothing
set linetype 2 linecolor rgb "#CC6677"  # Lock-based
set linetype 3 linecolor rgb "#88CCEE"  # TM
set linetype 4 linecolor rgb "#44AA99"  # SCR
set linetype 5 linecolor rgb "#117733"  # RSS

unset xtics
unset x2tics

set ytics 20
set yrange [ 0 : 99 ] noreverse writeback
set samples 8

# Plot each application with all five technologies
set ylabel " "
set y2label "NOP" font ',55'
plot "./dats/nop-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 t "Shared-nothing", \
     "./dats/nop-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 t "Lock-based", \
     "./dats/nop-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 t "TM", \
     "./dats/nop-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 t "SCR", \
     "./dats/nop-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 t "RSS"

set ylabel " "
set y2label "SBridge" font ',55'
plot "./dats/sbridge-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 fs notitle, \
     "./dats/sbridge-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 fs notitle, \
     "./dats/sbridge-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 fs notitle, \
     "./dats/sbridge-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 fs notitle, \
     "./dats/sbridge-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 fs notitle

set ylabel " "
set y2label "Policer" font ',55'
plot "./dats/pol-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 fs notitle, \
     "./dats/pol-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 fs notitle, \
     "./dats/pol-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 fs notitle, \
     "./dats/pol-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 fs notitle, \
     "./dats/pol-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 fs notitle

set ylabel "Throughput (Mpps)"
set y2label "FW" font ',55'
plot "./dats/fw-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 fs notitle, \
     "./dats/fw-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 fs notitle, \
     "./dats/fw-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 fs notitle, \
     "./dats/fw-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 fs notitle, \
     "./dats/fw-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 fs notitle

set ylabel " "
set y2label "NAT" font ',55'
plot "./dats/nat-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 fs notitle, \
     "./dats/nat-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 fs notitle, \
     "./dats/nat-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 fs notitle, \
     "./dats/nat-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 fs notitle, \
     "./dats/nat-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 fs notitle

set ylabel " "
set y2label "CL" font ',55'
plot "./dats/cl-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 fs notitle, \
     "./dats/cl-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 fs notitle, \
     "./dats/cl-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 fs notitle, \
     "./dats/cl-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 fs notitle, \
     "./dats/cl-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 fs notitle

set ylabel " "
set y2label "PSD" font ',55'
plot "./dats/psd-sn-uniform.dat" using 2:3:4:xtic(1) w histogram lt 1 fs notitle, \
     "./dats/psd-locks-uniform.dat" using 2:3:4:xtic(1) w histogram lt 2 fs notitle, \
     "./dats/psd-tm-uniform.dat" using 2:3:4:xtic(1) w histogram lt 3 fs notitle, \
     "./dats/psd-scr-uniform.dat" using 2:3:4:xtic(1) w histogram lt 4 fs notitle, \
     "./dats/psd-rss-uniform.dat" using 2:3:4:xtic(1) w histogram lt 5 fs notitle

set tic scale 0
set xtics ()

unset multiplot
unset key
unset xrange
