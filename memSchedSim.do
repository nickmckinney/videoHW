onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /memScheduler_tb/upstream/addr
add wave -noupdate /memScheduler_tb/upstream/readReq
add wave -noupdate /memScheduler_tb/upstream/readNext
add wave -noupdate /memScheduler_tb/upstream/busy
add wave -noupdate /memScheduler_tb/upstream/dataReady
add wave -noupdate -radix hexadecimal /memScheduler_tb/upstream/data

add wave -noupdate -divider -height 50 {Port 0}
add wave -noupdate -radix hexadecimal {/memScheduler_tb/ports[0]/addr}
add wave -noupdate {/memScheduler_tb/ports[0]/readReq}
add wave -noupdate {/memScheduler_tb/ports[0]/busy}
add wave -noupdate {/memScheduler_tb/ports[0]/dataReady}
add wave -noupdate -radix hexadecimal {/memScheduler_tb/ports[0]/data}

add wave -noupdate -divider -height 50 {Port 1}
add wave -noupdate -radix hexadecimal {/memScheduler_tb/ports[1]/addr}
add wave -noupdate {/memScheduler_tb/ports[1]/readReq}
add wave -noupdate {/memScheduler_tb/ports[1]/busy}
add wave -noupdate {/memScheduler_tb/ports[1]/dataReady}
add wave -noupdate -radix hexadecimal {/memScheduler_tb/ports[1]/data}

add wave -noupdate -divider -height 50 {Port 2}
add wave -noupdate -radix hexadecimal {/memScheduler_tb/ports[2]/addr}
add wave -noupdate {/memScheduler_tb/ports[2]/readReq}
add wave -noupdate {/memScheduler_tb/ports[2]/busy}
add wave -noupdate {/memScheduler_tb/ports[2]/dataReady}
add wave -noupdate -radix hexadecimal {/memScheduler_tb/ports[2]/data}

add wave -noupdate -divider -height 50 {DUT}
add wave -noupdate /memScheduler_tb/dut/clk
add wave -noupdate /memScheduler_tb/dut/rst_n
add wave -noupdate /memScheduler_tb/dut/reqOwnBufHead
add wave -noupdate /memScheduler_tb/dut/reqOwnBufTail
add wave -noupdate /memScheduler_tb/dut/allClientReadReq
add wave -noupdate /memScheduler_tb/dut/nextReq
add wave -noupdate -radix hexadecimal /memScheduler_tb/dut/nextAddress
add wave -noupdate /memScheduler_tb/dut/reqOwnBufNextHead
add wave -noupdate /memScheduler_tb/dut/allDataReady
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 290
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {223 ps}

run -all
