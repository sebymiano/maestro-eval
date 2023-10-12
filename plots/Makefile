TARGETS += churn packet-size skew technologies-zipf technologies vpp latency-sn
OUT_DIR=out

define plot
	@echo Plotting $(1) ...

	@gnuplot $(1).gp

	@pdfcrop $(OUT_DIR)/$(1).pdf > /dev/null
	@mv $(OUT_DIR)/$(1)-crop.pdf $(OUT_DIR)/$(1).pdf

	@pdftoppm -png $(OUT_DIR)/$(1).pdf > $(OUT_DIR)/$(1).png
endef

all: $(TARGETS)

process: process-raws.py
	@mkdir -p $(OUT_DIR)
	@./process-raws.py

$(TARGETS): process
	$(call plot,$@)

clean:
	rm -rf $(OUT_DIR)/* dats/*
