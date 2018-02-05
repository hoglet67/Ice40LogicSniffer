#!/bin/bash

TOP=Logic_Sniffer
NAME=sniffer
PACKAGE=tq144:4k

SRCS="../src/async_fifo.v ../src/BRAM10k9bit.v ../src/clockman.v ../src/controller.v ../src/core.v ../src/data_align.v ../src/decoder.v ../src/delay_fifo.v ../src/demux.v ../src/filter.v ../src/flags.v ../src/gray.v ../src/iomodules.v ../src/Logic_Sniffer.v ../src/meta.v ../src/regs.v ../src/rle_enc.v ../src/sampler.v ../src/serial_receiver.v ../src/serial_transmitter.v ../src/serial.v ../src/spi_receiver.v ../src/spi_slave.v ../src/spi_transmitter.v ../src/sram_interface.v ../src/stage.v ../src/sync.v ../src/timer.v ../src/trigger_adv.v ../src/trigger.v
"

./clean.sh

yosys -q -f "verilog -Duse_sb_io" -l ${NAME}.log -p "synth_ice40 -top ${TOP} -abc2 -blif ${NAME}.blif" ${SRCS}
arachne-pnr -d 8k -P ${PACKAGE} -p blackice.pcf ${NAME}.blif -o ${NAME}.txt
icepack ${NAME}.txt ${NAME}.bin
icetime -d hx8k -P ${PACKAGE} -t ${NAME}.txt
truncate -s 135104 ${NAME}.bin
