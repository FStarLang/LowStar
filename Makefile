# LowStar — Low* libraries and examples
#
# This repo provides the Low* / LowStar libraries (HyperStack, HyperHeap,
# LowStar.Buffer, Modifies, etc.) and example programs built on top of them.
#
# Prerequisites:
#   - Z3 (in PATH)
#   - OCaml toolchain (for building F* if needed)

FSTAR_HOME ?= $(realpath FStar)
FSTAR_EXE  ?= $(FSTAR_HOME)/out/bin/fstar.exe

# F* standard library (core modules that ship with F*)
FSTAR_ULIB = $(FSTAR_HOME)/ulib

# LowStar library directory
LOWSTAR_LIB = $(realpath lib)
LOWSTAR_LEGACY = $(realpath lib/legacy)

# --already_cached: treat Prims and FStar modules as cached from the
# FStar submodule's ulib.checked, but NOT LowStar modules — those are
# verified from our lib/ sources.
# NOTE: The FStar.HyperStack/Modifies/etc. modules in lib/ are currently
# also present in the FStar submodule (master branch) and use its cache.
# Once the fstar2 cleanup merges to master, update --already_cached to
# also exclude those FStar.* modules with e.g. -FStar.HyperStack.
ALREADY_CACHED = Prims FStar -LowStar

# Common F* flags
FSTAR_FLAGS = \
  --cache_dir $(CACHE_DIR) \
  --odir $(OUTPUT_DIR) \
  --already_cached '$(ALREADY_CACHED)' \
  --include $(LOWSTAR_LIB) \
  --include $(LOWSTAR_LEGACY) \
  $(foreach d,$(EXAMPLE_DIRS),--include $(d)) \
  --warn_error -321

CACHE_DIR  = _cache
OUTPUT_DIR = _output

FSTAR = $(FSTAR_EXE) $(FSTAR_FLAGS) $(OTHERFLAGS)

.PHONY: all lib examples clean depend fstar

all: lib examples

# -------------------------------------------------------------------------
# Build F* if needed
# -------------------------------------------------------------------------

fstar: $(FSTAR_EXE)

$(FSTAR_EXE):
	@if [ ! -f $(FSTAR_EXE) ]; then \
	  echo "*** F* not found at $(FSTAR_EXE), building it..." ; \
	  git submodule update --init --recursive ; \
	  $(MAKE) -C $(FSTAR_HOME) -j ; \
	fi

# -------------------------------------------------------------------------
# Dependency analysis
# -------------------------------------------------------------------------

# Collect all .fst/.fsti files in lib/
LIB_FILES = $(wildcard lib/*.fst lib/*.fsti lib/legacy/*.fst lib/legacy/*.fsti)

# Collect all example .fst/.fsti files
EXAMPLE_DIRS = \
  examples/data_structures \
  examples/demos/low-star \
  examples/doublylinkedlist \
  examples/generic \
  examples/misc \
  examples/oplss2021 \
  examples/preorders \
  examples/sample_project \
  examples/tests

EXAMPLE_FILES = $(foreach d,$(EXAMPLE_DIRS),$(wildcard $(d)/*.fst $(d)/*.fsti))

ALL_FILES = $(LIB_FILES) $(EXAMPLE_FILES)

# Generate .depend using F*'s --dep full
.depend: $(FSTAR_EXE) $(ALL_FILES)
	@mkdir -p $(CACHE_DIR) $(OUTPUT_DIR)
	$(FSTAR) --dep full $(ALL_FILES) \
	  --output_deps_to $@

depend: .depend

-include .depend

# -------------------------------------------------------------------------
# Verification — use ALL_CHECKED_FILES from .depend
# -------------------------------------------------------------------------

$(CACHE_DIR)/%.checked: | .depend
	@mkdir -p $(CACHE_DIR)
	$(FSTAR) $< --cache_checked_modules
	@touch -c $@

lib: $(ALL_CHECKED_FILES)

examples: $(ALL_CHECKED_FILES)

# -------------------------------------------------------------------------
# Clean
# -------------------------------------------------------------------------

clean:
	rm -rf $(CACHE_DIR) $(OUTPUT_DIR) .depend
