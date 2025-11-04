CRYSTAL ?= crystal
TEMP_DIR ?= temp

DEMOS := \
	interactive_builder_demo \
	ui_builder_demo

.PHONY: build-demos clean tempdir

build-demos: $(addprefix $(TEMP_DIR)/,$(DEMOS))

tempdir:
	mkdir -p $(TEMP_DIR)

$(TEMP_DIR)/interactive_builder_demo: examples/interactive_builder_demo.cr | tempdir
	$(CRYSTAL) build $< -o $@

$(TEMP_DIR)/ui_builder_demo: examples/ui_builder_demo.cr | tempdir
	$(CRYSTAL) build $< -o $@

clean:
	rm -rf $(TEMP_DIR)
