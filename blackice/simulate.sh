#!/bin/bash

SRCS="../src/async_fifo.v ../src/BRAM4k8bit.v ../src/controller.v ../src/core.v ../src/data_align.v ../src/decoder.v ../src/delay_fifo.v ../src/demux.v ../src/filter.v ../src/flags.v ../src/iomodules.v ../src/Logic_Sniffer.v ../src/meta.v ../src/regs.v ../src/rle_enc.v ../src/sampler.v ../src/serial_receiver.v ../src/serial_transmitter.v ../src/serial.v  ../src/sram_interface.v ../src/stage.v ../src/sync.v  ../src/trigger.v"

iverilog -DSIMULATION -I ../src/ ../src/Logic_Sniffer_tb.v $SRCS
./a.out  
gtkwave -g -a signals.gtkw dump.vcd
