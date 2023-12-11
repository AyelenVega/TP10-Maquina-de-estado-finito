.PHONY : all receptor_ir wav-receptor_

all : receptor_ir

receptor_ir : design.vhd testbench.vhd
	ghdl -i --std=08 *.vhd
	ghdl -m --std=08 receptor_ir_tb
	ghdl -r --std=08 receptor_ir_tb

wav-receptor_ir :
	ghdl -i --std=08 *.vhd
	ghdl -m --std=08 receptor_ir_tb
	ghdl -r --std=08 receptor_ir_tb --assert-level=none --wave=receptor_ir_tb.ghw
	gtkwave -f receptor_ir_tb.ghw

clean :
	rm design.o e~receptor_ir_tb.o testbench.o receptor_ir_tb.exe work-obj08.cf receptor_ir_tb.ghw