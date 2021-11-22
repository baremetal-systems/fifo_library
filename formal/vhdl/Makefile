dut=simple_fifo

.PHONY: all
all: 
	formal
	show_prove

.PHONY: formal
formal:
	sby -f $(dut).sby

.PHONY: prove
show_prove:
	gtkwave $(dut)_cover/engine_0/trace1.vcd
	gtkwave $(dut)_cover/engine_0/trace2.vcd

.PHONY: clean
clean:
	rm -rf $(dut)_bmc $(dut)_cover
