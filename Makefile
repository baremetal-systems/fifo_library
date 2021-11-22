mkfile_path := $(abspath $(firstword $(MAKEFILE_LIST)))
current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))
lang ?= vhdl

src_path = $(current_dir)/rtl/$(lang)
bench_path = $(current_dir)/bench/$(lang)
formal_path = $(current_dir)/formal/$(lang)
sim_path = $(current_dir)/sim

dut ?= simple_fifo
src += $(dut).vhd


.PHONY: formal
$(lang)_formal:
	cd $(formal_path) && $(MAKE) formal

$(lang)_formal_clean:
	cd $(formal_path) && $(MAKE) clean

$(lang)_show_prove:
	cd $(formal_path) && $(MAKE) show_prove

.PHONY: sim
vhdl_sim:
	cd $(sim_path); ghdl -a --std=08 $(src_path)/$(src) $(bench_path)/tb_$(dut).vhd; \
		ghdl -e --std=08 tb_$(dut); \
		ghdl -r tb_$(dut) --vcd=tb_$(dut).vcd; \
		cd $(current_dir);

vhdl_show_sim:
	cd $(sim_path); gtkwave tb_$(dut).vcd

$(lang)_sim_all:
	$(MAKE) $(lang)_sim
	$(MAKE) $(lang)_show_sim

.PHONY: all
$(lang)_all:
	$(MAKE) $(lang)_sim
	echo "performing formal checks"
	$(MAKE) $(lang)_formal
	echo "Showing simulation waveform"
	$(Make) $(lang)_show_sim


.PHONY: clean
$(lang)_clean:
	$(MAKE) $(lang)_formal_clean
	rm -rf $(sim_path)/*
