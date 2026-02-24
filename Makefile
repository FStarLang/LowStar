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

# -------------------------------------------------------------------------
# Source files
# -------------------------------------------------------------------------

# Example directories (self-contained, no module name collisions)
EXAMPLE_DIRS = \
  examples/data_structures \
  examples/demos/low-star \
  examples/doublylinkedlist \
  examples/generic \
  examples/interactive \
  examples/layeredeffects \
  examples/low-mitls-experiments \
  examples/miniparse \
  examples/misc \
  examples/oplss2021 \
  examples/preorders \
  examples/regional \
  examples/sample_project \
  examples/tactics/old \
  examples/tests

# Test directories (no module name collisions within this set)
TEST_DIRS = \
  tests/bug-reports/closed \
  tests/extraction \
  tests/micro-benchmarks \
  tests/tactics

# Note: directories excluded from the unified build due to module name
# collisions or external dependencies:
#   tests/struct/*.pos/  - each has Test.fst (8-way collision)
#   tests/error-messages/ - Inference.fst collides with micro-benchmarks
#   tests/prettyprinting/ - Misc.fst uses unresolved U32 abbreviation
#   doc/old/tutorial/     - exercises/solutions share module names
#   examples/crypto/      - needs CoreCrypto, Platform.Bytes
#   examples/kv_parsing/  - needs C.Loops
#   examples/old/         - needs external TLS/crypto deps

ALL_DIRS = $(EXAMPLE_DIRS) $(TEST_DIRS)

EXAMPLE_FILES = $(foreach d,$(ALL_DIRS),$(wildcard $(d)/*.fst $(d)/*.fsti))

# Filter out files requiring C.Loops (from KaRaMeL, not in F*)
EXCLUDED_FILES = \
  examples/miniparse/MiniParse.Impl.List.fst \
  examples/miniparse/MiniParse.Tac.Impl.fst \
  examples/miniparse/MiniParseExample.fst \
  examples/miniparse/MiniParseExample.fsti \
  examples/miniparse/MiniParseExample3.fst \
  examples/miniparse/MiniParseExample3.fsti \
  examples/tactics/old/StringPrinter.Base.fst \
  examples/tactics/old/StringPrinter.Rec.fst \
  examples/tactics/old/StringPrinter.RecC.fst \
  examples/tactics/old/StringPrinterTest.fst \
  examples/tactics/old/StringPrinterTest.Aux.fst

EXAMPLE_FILES := $(filter-out $(EXCLUDED_FILES),$(EXAMPLE_FILES))

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
  $(foreach d,$(ALL_DIRS),--include $(d)) \
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
