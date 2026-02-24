# LowStar — Low\* Libraries and Examples

This repository contains the **Low\*** libraries and example programs, extracted from the
[F\* repository](https://github.com/FStarLang/FStar). Low\* is a subset of F\* designed
for programming and verifying low-level, sequential, C-like code. It provides a memory
model based on hierarchical regions (HyperStack) and a buffer library for safe, verified
manipulation of heap-allocated arrays.

## Repository Structure

```
LowStar/
├── FStar/                  # Git submodule: FStarLang/FStar (fstar2 branch)
├── lib/                    # Low* library modules
│   ├── LowStar.*.fst/i    # Core LowStar buffer, modifies, endianness, etc.
│   ├── FStar.HyperStack.*  # HyperStack memory model and ST effect
│   ├── FStar.Monotonic.*   # Monotonic HyperHeap, HyperStack, DependentMap, Seq
│   ├── FStar.Modifies*     # Modifies and ModifiesGen frameworks
│   ├── legacy/             # Legacy compatibility modules
│   │   ├── FStar.Buffer.*  # Old-style buffer library
│   │   ├── FStar.Pointer.* # Pointer library
│   │   └── LowStar.*      # Buffer compatibility shims
│   ├── experimental/       # Experimental modules
│   │   └── FStar.InteractiveHelpers.*
│   └── ml/                 # OCaml extraction support
│       ├── FStar_Buffer.ml
│       └── FStar_HyperStack_ST.ml
├── examples/               # Example programs using Low*
│   ├── data_structures/    # LowStar.Lens — buffer lens utilities
│   ├── demos/              # Low* tutorial demos
│   │   └── low-star/       # Main Low* demo (Demo.fst)
│   ├── doublylinkedlist/   # Verified doubly-linked list
│   ├── generic/            # Interop example
│   ├── layeredeffects/     # LowParseWriters and related
│   ├── low-mitls-experiments/ # miTLS Low* experiments
│   ├── misc/               # Miscellaneous (WithLocal)
│   ├── oplss2021/          # OPLSS 2021 MemCpy tutorial
│   ├── preorders/          # Closure example
│   ├── regional/           # Regional vector example
│   ├── sample_project/     # Sample standalone Low* project
│   └── tests/              # Low*-specific tests (BufferView, HyperStack)
├── doc/                    # Tutorial exercises and solutions
├── tests/                  # Struct tests, bug reports, micro-benchmarks
├── Makefile                # Top-level build system
├── README.md               # This file
└── LICENSE
```

## What Was Moved from FStar

The following modules were moved from the F\* repository's `ulib/` directory:

### Core Low\* Libraries (`ulib/` → `lib/`)

| Module Family | Description |
|---|---|
| `LowStar.Buffer`, `LowStar.Monotonic.Buffer`, etc. | Safe buffer manipulation over the HyperStack memory model |
| `LowStar.Modifies`, `LowStar.ModifiesPat` | Modifies-clause reasoning for buffers |
| `LowStar.BufferView.{Up,Down}` | Buffer view coercions |
| `LowStar.BufferOps` | Buffer read/write operations |
| `LowStar.{ConstBuffer,ImmutableBuffer,UninitializedBuffer}` | Specialized buffer variants |
| `LowStar.PrefixFreezableBuffer` | Prefix-freezable buffer |
| `LowStar.{Comment,Endianness,Failure,Ignore,Literal,Printf}` | Extraction support and utilities |
| `LowStar.{RVector,Regional,Regional.Instances,Vector}` | Regional vectors |
| `FStar.HyperStack`, `FStar.HyperStack.ST`, `FStar.HyperStack.All` | HyperStack memory model and ST effect |
| `FStar.Monotonic.HyperHeap` | Hierarchical region-based heap |
| `FStar.Monotonic.HyperStack` | Monotonic HyperStack |
| `FStar.Monotonic.{DependentMap,Map,Seq}` | Monotonic data structures over HyperStack |
| `FStar.ModifiesGen`, `FStar.Modifies` | Generic and instantiated modifies frameworks |

### Legacy Modules (`ulib/legacy/` → `lib/legacy/`)

| Module | Description |
|---|---|
| `FStar.Buffer`, `FStar.Buffer.Quantifiers`, `FStar.BufferNG` | Old buffer library (superseded by `LowStar.Buffer`) |
| `FStar.Pointer.{Base,Derived1,Derived2,Derived3}` | Structured pointer library |
| `FStar.TaggedUnion` | Tagged union support |
| `FStar.HyperStack.IO` | I/O operations on HyperStack |
| `LowStar.BufferCompat`, `LowStar.ToFStarBuffer` | Compatibility shims |

### Example Programs (`examples/` → `examples/`)

| Directory | Description |
|---|---|
| `demos/low-star/` | Introductory Low\* demos |
| `doublylinkedlist/` | Verified doubly-linked list implementation |
| `data_structures/` | LowStar.Lens buffer lens utilities |
| `low-mitls-experiments/` | miTLS protocol experiments |
| `regional/` | Regional vector example |
| `sample_project/` | Template for standalone Low\* projects |

## Prerequisites

- **F\***: Available via the `FStar/` submodule
- **Z3**: SMT solver (version compatible with F\*), must be in `PATH`

## Building

```bash
# Initialize the FStar submodule
git submodule update --init --recursive

# Build F* (automatic if not already built)
# Or manually: cd FStar && make -j && cd ..

# Or point to an existing F* build:
# export FSTAR_HOME=/path/to/FStar

# Verify LowStar libraries and examples
make all

# Or individually:
make lib       # verify lib/ only
make examples  # verify examples/ only
make clean     # remove build artifacts
```

## Dependency Scanning

The Makefile uses F\*'s `--dep full` mode for dependency analysis:

```bash
make depend
```

This produces a `.depend` file that is automatically included by `make`.

## License

See [LICENSE](LICENSE).
