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

# LowStar library directories
LOWSTAR_LIB          = $(realpath lib)
LOWSTAR_LEGACY       = $(realpath lib/legacy)
LOWSTAR_EXPERIMENTAL = $(realpath lib/experimental)

# --already_cached: treat Prims and core FStar modules as cached from the
# F* distribution, but NOT the FStar.* and LowStar.* modules we provide
# in lib/ (since those were removed from fstar2's ulib).
#
# Compute module names from lib/ files to auto-generate exclusions:
LIB_ALL_FILES = $(wildcard lib/*.fst lib/*.fsti \
                           lib/legacy/*.fst lib/legacy/*.fsti \
                           lib/experimental/*.fst lib/experimental/*.fsti)
LIB_MODULE_NAMES = $(sort $(basename $(notdir $(LIB_ALL_FILES))))
FSTAR_LIB_MODULES = $(filter FStar.%,$(LIB_MODULE_NAMES))
ALREADY_CACHED_EXCLUSIONS = $(addprefix -,$(FSTAR_LIB_MODULES)) -LowStar
ALREADY_CACHED = Prims FStar $(ALREADY_CACHED_EXCLUSIONS)

# Example directories — only self-contained examples that don't need
# external dependencies (Platform.Bytes, CoreCrypto, KaRaMeL, etc.)
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

# All source files for dependency analysis
ALL_SOURCE_FILES = $(wildcard lib/*.fst lib/*.fsti \
                              lib/legacy/*.fst lib/legacy/*.fsti \
                              lib/experimental/*.fst lib/experimental/*.fsti) \
                   $(EXAMPLE_FILES)

# Common F* flags
FSTAR_FLAGS = \
  --cache_dir $(CACHE_DIR) \
  --odir $(OUTPUT_DIR) \
  --already_cached '$(ALREADY_CACHED)' \
  --include $(LOWSTAR_LIB) \
  --include $(LOWSTAR_LEGACY) \
  --include $(LOWSTAR_EXPERIMENTAL) \
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
	  echo '*** F* not found at $(FSTAR_EXE), building it...' ; \
	  git submodule update --init --recursive ; \
	  $(MAKE) -C $(FSTAR_HOME) -j ; \
	fi

# -------------------------------------------------------------------------
# Dependency analysis
# -------------------------------------------------------------------------

.depend: $(FSTAR_EXE) $(ALL_SOURCE_FILES)
	@mkdir -p $(CACHE_DIR) $(OUTPUT_DIR)
	$(FSTAR) --dep full $(ALL_SOURCE_FILES) \
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
