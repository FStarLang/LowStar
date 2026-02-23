# LowStar — Low* libraries and examples
#
# This repo provides the Low* / LowStar libraries (HyperStack, HyperHeap,
# LowStar.Buffer, Modifies, etc.) and example programs built on top of them.
#
# Prerequisites:
#   - F* (via the FStar/ submodule)
#   - Z3 (in PATH)

FSTAR_HOME ?= $(realpath FStar)
FSTAR_EXE  ?= $(FSTAR_HOME)/out/bin/fstar.exe

# F* standard library (core modules that ship with F*)
FSTAR_ULIB = $(FSTAR_HOME)/ulib

# LowStar library directory
LOWSTAR_LIB = $(realpath lib)
LOWSTAR_LEGACY = $(realpath lib/legacy)

# Common F* flags
FSTAR_FLAGS = \
  --cache_dir $(CACHE_DIR) \
  --odir $(OUTPUT_DIR) \
  --already_cached 'Prims FStar' \
  --include $(LOWSTAR_LIB) \
  --include $(LOWSTAR_LEGACY) \
  --warn_error -321

CACHE_DIR  = _cache
OUTPUT_DIR = _output

FSTAR = $(FSTAR_EXE) $(FSTAR_FLAGS) $(OTHERFLAGS)

.PHONY: all lib examples clean depend

all: lib examples

# -------------------------------------------------------------------------
# Dependency analysis
# -------------------------------------------------------------------------

# Collect all .fst/.fsti files in lib/
LIB_FILES = $(wildcard lib/*.fst lib/*.fsti lib/legacy/*.fst lib/legacy/*.fsti)

# Collect all example .fst/.fsti files
EXAMPLE_DIRS = \
  examples/crypto \
  examples/data_structures \
  examples/demos/low-star \
  examples/demos/fstar_and_lowstar \
  examples/doublylinkedlist \
  examples/generic \
  examples/kv_parsing \
  examples/layeredeffects \
  examples/low-mitls-experiments \
  examples/misc \
  examples/old \
  examples/old/tls-record-layer \
  examples/oplss2021 \
  examples/preorders \
  examples/regional \
  examples/sample_project \
  examples/tests

EXAMPLE_FILES = $(foreach d,$(EXAMPLE_DIRS),$(wildcard $(d)/*.fst $(d)/*.fsti))

ALL_FILES = $(LIB_FILES) $(EXAMPLE_FILES)

# Generate .depend using F*'s --dep full
.depend: $(ALL_FILES)
	@mkdir -p $(CACHE_DIR) $(OUTPUT_DIR)
	$(FSTAR) --dep full $(ALL_FILES) \
	  --output_deps_to $@

depend: .depend

-include .depend

# -------------------------------------------------------------------------
# Verification
# -------------------------------------------------------------------------

$(CACHE_DIR)/%.checked: | .depend
	@mkdir -p $(CACHE_DIR)
	$(FSTAR) $< --cache_checked_modules
	@touch -c $@

lib: $(addprefix $(CACHE_DIR)/,$(addsuffix .checked,$(notdir $(LIB_FILES))))

examples: lib $(addprefix $(CACHE_DIR)/,$(addsuffix .checked,$(notdir $(EXAMPLE_FILES))))

# -------------------------------------------------------------------------
# Clean
# -------------------------------------------------------------------------

clean:
	rm -rf $(CACHE_DIR) $(OUTPUT_DIR) .depend
