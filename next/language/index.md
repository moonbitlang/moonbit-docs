# MoonBit Language

MoonBit is an AI native programming language toolchain for cloud and edge computing. It targets `wasm`, `wasm-gc`, `js`, and `native`, and works well for mixed-backend projects in one module.

**Status**

MoonBit is currently in beta-preview.

MoonBit can already be used in production, with backwards-incompatible changes evaluated seriously and compiler bugs expected to be rare. MoonBit is developed by a full-time team with deep language-toolchain experience, so the ecosystem is moving quickly.

**Main advantages**

- Generate significantly smaller WASM output than any existing solutions.
- Much faster runtime performance.
- State of the art compile-time performance.
- Simple but practical, data-oriented language design.

## Manual map

The language section is a manual, not a single tutorial path. Start with the orientation pages if you are new to MoonBit, then jump to the topic you need. The navigation order follows the same groups.

**Orientation**

- [Introduction](introduction.md): expressions, bindings, names, keywords, and entry points.
- [Fundamentals](fundamentals.md): built-ins, functions, control flow, data types, pattern matching, and common syntax.

**Core language**

- [Method and Trait](methods.md): methods, operators, traits, trait objects, and built-in traits.
- [Deriving traits](derive.md): generated implementations for common traits.
- [Error handling](error-handling.md): error types, throwing, catching, and inference.
- [Managing Projects with Packages](packages.md): packages, modules, access control, and virtual packages.

**Development model**

- [Writing Tests](tests.md): test blocks, snapshot tests, and blackbox or whitebox tests.
- [Writing Benchmarks](benchmarks.md): benchmark blocks and output statistics.
- [Comments and Documentation](docs.md): comments, doc comments, and literate `.mbt.md` files.
- [Attribute](attributes.md): attributes that affect declarations, visibility, warnings, externals, and configuration.

**Interop and advanced topics**

- [Foreign Function Interface (FFI)](ffi.md): external types, foreign functions, exports, and lifetime management.
- [Async programming support](async-experimental.md): experimental async functions, task groups, cancellation, and JavaScript support.
- [Formal Verification](verification.md): proof setup, specifications, running the verifier, and the trust model.

**Reference**

- [Error codes](error_codes/index.md): diagnostic reference pages.

```{only} html
[Download this section in Markdown](path:/download/language/summary.md)
```

```{toctree}
:hidden:
:caption: Orientation

introduction
fundamentals
```

```{toctree}
:hidden:
:caption: Core language

methods
derive
error-handling
packages
```

```{toctree}
:hidden:
:caption: Development model

tests
benchmarks
docs
attributes
```

```{toctree}
:hidden:
:caption: Interop and advanced topics

ffi
async-experimental
verification
```

```{toctree}
:hidden:
:caption: Reference

error_codes/index
```
