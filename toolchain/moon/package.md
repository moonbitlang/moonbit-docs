# Package Configuration

moon uses a package file to identify and describe a package. The legacy format
is `moon.pkg.json`, and the new format is `moon.pkg`. For full JSON schema,
please check [moon's repository](https://github.com/moonbitlang/moon/blob/main/crates/moonbuild/template/pkg.schema.json).

## New format (`moon.pkg`)

The new format is a concise DSL. You can generate or reformat it from an
existing `moon.pkg.json` with:

```bash
moon fmt -C <module_dir>
```

Example:

```moonbit
import {
  "moonbit-community/language/packages/virtual",
}

options(
  "is-main": true,
  overrides: [ "moonbit-community/language/packages/implement" ],
)
```

In `moon.pkg`, dependencies are declared in an `import { ... }` block. Use
`@alias` to set a custom alias:

```moonbit
import {
  "moonbit-community/language/packages/pkgA",
  "moonbit-community/language/packages/pkgC" @c,
  "moonbitlang/core/builtin",
}
```

All other fields from `moon.pkg.json` move into a single `options(...)` block.
The key names and value shapes are unchanged; the legacy keys that contain `-` must be
quoted.

```moonbit
options(
  "virtual": { "has-default": true },
)
```

The `moon.pkg` format allows comments `//...`.

Full syntax of `moon.pkg` is as follows:

```default
moon_pkg ::= statement*
statement ::= import | assign | apply

import ::= "import" "{" (import_item ",")* import_item? "}" import_kind?
import_item ::= STRING ("@" PKG_NAME)?
import_kind ::= "for" STRING

assign ::= LIDENT "=" expr

apply ::= LIDENT "(" (argument ",")* argument? ")"
argument ::= LIDENT ":" expr | STRING ":" expr  

expr ::= array | object | apply | STRING | INT | "true" | "false"
array ::= "[" (expr ",")* expr? "]"
object ::= "{" (field ",")* field? "}"
```

## Name

The package name is not configurable; it is determined by the directory name of the package.

## Formatter

The `formatter` field configures `moon fmt` for this package. Currently it
supports `ignore`, a list of file names that the formatter should skip.

This is useful for generated files or files that you intentionally keep in a
different format. Files produced by `pre-build` are already skipped
automatically, so `formatter.ignore` is mainly for additional files you want to
exclude.

### moon.pkg

```moonbit
options(
  formatter: {
    ignore: [ "generated.mbt", "snapshot.mbt" ],
  },
)
```

### moon.pkg.json

```json
{
  "formatter": {
    "ignore": ["generated.mbt", "snapshot.mbt"]
  }
}
```

## is-main

The `is-main` field is used to specify whether a package needs to be linked into an executable file.

The output of the linking process depends on the backend. When this field is set to `true`:

- For the Wasm and `wasm-gc` backends, a standalone WebAssembly module will be generated.
- For the `js` backend, a standalone JavaScript file will be generated.

### moon.pkg

```moonbit
options(
  "is-main": true,
)
```

### moon.pkg.json

```json
{
  "is-main": true
}
```

## Importing dependencies

### Import

The `import` field is used to specify other packages that a package depends on.

For example, the following imports `pkgA` and `pkgC`, aliasing `pkgC` to `c`.
User can write `@c` to access definitions from `pkgC`.

### moon.pkg

```moonbit
import {
  "moonbit-community/language/packages/pkgA",
  "moonbit-community/language/packages/pkgC" @c,
  "moonbitlang/core/builtin",
}
```

### moon.pkg.json

```json
{
    "import": [
        "moonbit-community/language/packages/pkgA",
        {
            "path": "moonbit-community/language/packages/pkgC",
            "alias": "c"
        },
        "moonbitlang/core/builtin"
    ]
}
```

Most core packages are not special here: if you use `@json`, `@test`, or other
ordinary core aliases, add the corresponding `moonbitlang/core/...` package to
`import` to avoid `core_package_not_imported` warnings.

`prelude` is the exception. It is available by default, so the names it exposes
do not need an explicit package import.

### Test import

The test import is used to specify other packages that the black-box test package of this package depends on,
with the same format as `import`.

### moon.pkg

```moonbit
import {
  "path/to/package1",
  "path/to/package2" @pkg2,
} for "test"
```

### moon.pkg.json

```json
{
  "test-import": {
    "path/to/package1",
    {
      "path": "path/to/package2",
      "alias": "pkg2"
    }
  }
}
```

The `test-import-all` field is used to specify whether all public definitions from the package being tested should be imported (`true`) by default.

### White-box test import

The white-box test import is used to specify other packages that the white-box test package of this package depends on,
with the same format as `import`.

### moon.pkg

```moonbit
import {
  "path/to/package1",
  "path/to/package2" @pkg2,
} for "wbtest"
```

### moon.pkg.json

```json
{
  "wbtest-import": {
    "path/to/package1",
    {
      "path": "path/to/package2",
      "alias": "pkg2"
    }
  }
}
```

## Maximum Concurrent Tests

The `max-concurrent-tests` field limits how many tests from this package may
run at the same time when `moon test` executes the package.

This is useful when tests in the same package share ports, temporary files, or
other external resources that should not all run in parallel.

### moon.pkg

```moonbit
options(
  "max-concurrent-tests": 2,
)
```

### moon.pkg.json

```json
{
  "max-concurrent-tests": 2
}
```

## Conditional Compilation

The smallest unit of conditional compilation is a file.

In a conditional compilation expression, three logical operators are supported: `and`, `or`, and `not`, where the `or` operator can be omitted.

For example, `["or", "wasm", "wasm-gc"]` can be simplified to `["wasm", "wasm-gc"]`.

Conditions in the expression can be categorized into backends and optimization levels:

- **Backend conditions**: `"wasm"`, `"wasm-gc"`, and `"js"`
- **Optimization level conditions**: `"debug"` and `"release"`

Conditional expressions support nesting.

If a file is not listed in `"targets"`, it will be compiled under all conditions by default.

Example:

### moon.pkg

```moonbit
options(
  targets: {
    "only_js.mbt": ["js"],
    "only_wasm.mbt": ["wasm"],
    "only_wasm_gc.mbt": ["wasm-gc"],
    "all_wasm.mbt": ["wasm", "wasm-gc"],
    "not_js.mbt": ["not", "js"],
    "only_debug.mbt": ["debug"],
    "js_and_release.mbt": ["and", ["js"], ["release"]],
    "js_only_test.mbt": ["js"],
    "js_or_wasm.mbt": ["js", "wasm"],
    "wasm_release_or_js_debug.mbt": ["or", ["and", "wasm", "release"], ["and", "js", "debug"]]
  }
)
```

### moon.pkg.json

```json
{
  "targets": {
    "only_js.mbt": ["js"],
    "only_wasm.mbt": ["wasm"],
    "only_wasm_gc.mbt": ["wasm-gc"],
    "all_wasm.mbt": ["wasm", "wasm-gc"],
    "not_js.mbt": ["not", "js"],
    "only_debug.mbt": ["debug"],
    "js_and_release.mbt": ["and", ["js"], ["release"]],
    "js_only_test.mbt": ["js"],
    "js_or_wasm.mbt": ["js", "wasm"],
    "wasm_release_or_js_debug.mbt": ["or", ["and", "wasm", "release"], ["and", "js", "debug"]]
  }
}
```

## Supported Targets

The `supported-targets` option declares which backends a package is intended to support.
It uses a target-set expression, not an array:

### moon.pkg

```moonbit
options(
  "supported-targets": "js",
)
```

### moon.pkg.json

```json
{
  "supported-targets": "js"
}
```

Examples:

- `js` for a single backend
- `+js+wasm-gc` for an explicit set of backends
- `+all-js` for all backends except `js`

Legacy array syntax is still accepted for compatibility:

```json
{
  "supported-targets": ["js", "native"]
}
```

This is package metadata, not a conditional compilation rule:

- use `supported-targets` to declare the package's supported backend set
- use `targets` to include or exclude individual files for different backends
- use `preferred-target` in `moon.mod.json` to choose the default backend for commands such as `moon check`, `moon run`, and `moon build`

When both the module and the package declare `supported-targets`, the effective backend set is
their intersection.

Command behavior follows the selected backend:

- `moon check`, `moon build`, `moon test`, and `moon bench` keep only packages that support the selected backend
- `moon run` requires the selected package to support the selected backend
- `moon info` skips unsupported selected packages with a warning
- `moon bundle` skips package targets that do not support the selected backend

After root selection, Moon also checks reachable required dependencies. If a required dependency
does not support the selected backend, the command fails with a normal user-facing error.

Notes:

- omitting `supported-targets` means all backends are supported
- `--target all` expands to `wasm`, `wasm-gc`, `js`, and `native`, but not `llvm`
- `llvm` is still a valid `supported-targets` value
- legacy array syntax is deprecated, but still accepted for compatibility

A common setup is:

- mark a native-only package with `"supported-targets": "native"`
- set `"preferred-target": "native"` in `moon.mod.json`
- use `targets` only when some files inside the package differ by backend

## Native Stub Files

The `native-stub` field lists C stub source files that should be compiled with
this package for native builds.

This is commonly used together with [`extern "C"` declarations in the FFI
documentation](../../language/ffi.md), where the stub file provides wrapper
functions or adapter code that is easier to write in C than directly in
MoonBit.

Paths are relative to the package directory.

### moon.pkg

```moonbit
options(
  "native-stub": [ "stub.c", "helpers.c" ],
)
```

### moon.pkg.json

```json
{
  "native-stub": ["stub.c", "helpers.c"]
}
```

## Link Options

By default, moon only links packages where `is-main` is set to `true`. If you need to link other packages, you can specify this with the `link` option.

The `link` option is used to specify link options, and its value can be either a boolean or an object.

Currently, `link` does not work for the native backend. The behavior described
in this section applies to the `wasm`, `wasm-gc`, and `js` backends.

- When the `link` value is `true`, it indicates that the package should be linked. The output will vary depending on the backend specified during the build.

  ### moon.pkg

  ```moonbit
  options(
    link: true
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": true
  }
  ```
- When the `link` value is an object, it indicates that the package should be linked, and you can specify link options. For detailed configuration, please refer to the subpage for the corresponding backend.

### Wasm Backend Link Options

#### Common Options

- The `exports` option is used to specify the function names exported by the Wasm backend.

  For example, in the following configuration, the `hello` function from the current package is exported as the `hello` function in the Wasm module, and the `foo` function is exported as the `bar` function in the Wasm module. In the Wasm host, the `hello` and `bar` functions can be called to invoke the `hello` and `foo` functions from the current package.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm": {
        "exports": [ "hello", "foo:bar" ],
      },
      "wasm-gc": {
        "exports": [ "hello", "foo:bar" ],
      }
    }
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm": {
        "exports": [
          "hello",
          "foo:bar"
        ]
      },
      "wasm-gc": {
        "exports": [
          "hello",
          "foo:bar"
        ]
      }
    }
  }
  ```
- The `import-memory` option is used to specify the linear memory imported by the Wasm module.

  For example, the following configuration specifies that the linear memory imported by the Wasm module is the `memory` variable from the `env` module.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm": {
        "import-memory": {
          "module": "env",
          "name": "memory",
        },
      },
      "wasm-gc": {
        "import-memory": {
          "module": "env",
          "name": "memory",
        },
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm": {
        "import-memory": {
          "module": "env",
          "name": "memory"
        }
      },
      "wasm-gc": {
        "import-memory": {
          "module": "env",
          "name": "memory"
        }
      }
    }
  }
  ```
- The `memory-limits` option is used to specify the minimum and maximum size of
  the linear memory used by the Wasm module.
- The `shared-memory` option is used to enable shared linear memory.

  For example, the following configuration sets memory limits and enables
  shared memory for both the `wasm` and `wasm-gc` backends.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm": {
        "memory-limits": {
          "min": 1,
          "max": 65536,
        },
        "shared-memory": true,
      },
      "wasm-gc": {
        "memory-limits": {
          "min": 1,
          "max": 65535,
        },
        "shared-memory": true,
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm": {
        "memory-limits": {
          "min": 1,
          "max": 65536
        },
        "shared-memory": true
      },
      "wasm-gc": {
        "memory-limits": {
          "min": 1,
          "max": 65535
        },
        "shared-memory": true
      }
    }
  }
  ```
- The `export-memory-name` option is used to specify the name of the linear memory exported by the Wasm module.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm": {
        "export-memory-name": "memory",
      },
      "wasm-gc": {
        "export-memory-name": "memory",
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm": {
        "export-memory-name": "memory"
      },
      "wasm-gc": {
        "export-memory-name": "memory"
      }
    }
  }
  ```

#### Wasm Linear Backend Link Options

- The `heap-start-address` option is used to specify the starting address of the linear memory that can be used when compiling to the Wasm backend.

  For example, the following configuration sets the starting address of the linear memory to 1024.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm": {
        "heap-start-address": 1024,
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm": {
        "heap-start-address": 1024
      }
    }
  }
  ```

#### Wasm GC Backend Link Options

- The `use-js-string-builtin` option is used to specify whether the [JS String Builtin Proposal](https://github.com/WebAssembly/js-string-builtins/blob/main/proposals/js-string-builtins/Overview.md) should be enabled when compiling to the Wasm GC backend.
  It will make the `String` in MoonBit equivalent to the `String` in JavaScript host runtime.

  For example, the following configuration enables the JS String Builtin.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm-gc": {
        "use-js-builtin-string": true,
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm-gc": {
        "use-js-builtin-string": true
      }
    }
  }
  ```
- The `imported-string-constants` option is used to specify the imported string namespace used by the JS String Builtin Proposal, which is "_" by default.
  It should meet the configuration in the JS host runtime.

  For example, the following configuration and JS initialization configures the imported string namespace.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "wasm-gc": {
        "use-js-builtin-string": true,
        "imported-string-constants": "_",
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "wasm-gc": {
        "use-js-builtin-string": true,
        "imported-string-constants": "_"
      }
    }
  }
  ```

  ```javascript
  const { instance } = await WebAssembly.instantiate(bytes, {}, { importedStringConstants: "strings" });
  ```

### JS Backend Link Options

- The `exports` option is used to specify the function names to export in the JavaScript module.

  For example, in the following configuration, the `hello` function from the current package is exported as the `hello` function in the JavaScript module. In the JavaScript host, the `hello` function can be called to invoke the `hello` function from the current package.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "js": {
        "exports": [ "hello" ],
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "js": {
        "exports": [
          "hello"
        ]
      }
    }
  }
  ```
- The `format` option is used to specify the output format of the JavaScript module.

  The currently supported formats are:
  - `esm` (default)
  - `cjs`
  - `iife`

  For example, the following configuration sets the output format of the current package to ES Module.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "js": {
        "format": "esm",
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "js": {
        "format": "esm"
      }
    }
  }
  ```

### Native Backend Link Options

- The `cc` option is used to specify the compiler for compiling the `moonc`-generated C source files.
  It can be either a full path to the compiler or a simple name that is accessible via the PATH environment variable.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "native": {
        "cc": "/usr/bin/gcc13",
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "native": {
        "cc": "/usr/bin/gcc13"
      }
    }
  }
  ```
- The `cc-flags` option is used to override the default flags passed to the compiler.
  For example, you can use the following flag to define a macro called MOONBIT.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "native": {
        "cc-flags": "-DMOONBIT",
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "native": {
        "cc-flags": "-DMOONBIT"
      }
    }
  }
  ```
- The `cc-link-flags` option is used to override the default flags passed to the linker.
  Since the linker is invoked through the compiler driver (e.g., `cc` instead of `ld`, `cl` instead of `link`),
  you should prefix specific options with `-Wl,` or `/link ` when passing them.

  The following example strips symbol information from produced binary.

  ### moon.pkg

  ```moonbit
  options(
    link: {
      "native": {
        "cc-link-flags": "-s",
      },
    },
  )
  ```

  ### moon.pkg.json

  ```json
  {
    "link": {
      "native": {
        "cc-link-flags": "-s"
      }
    }
  }
  ```
- The `stub-cc` option is similar to `cc` but controls which compiler to use for compiling stubs.
  Although it can be different from `cc`, it is not recommended and should only be used for debugging purposes.
  Therefore, we strongly recommend to specify `cc` and `stub-cc` at the same time
  and make them consistent to avoid potential conflicts.
- The `stub-cc-flags` is similar to `cc-flags`. It only have effects on stubs compilation.
- The `stub-cc-link-flags` are similar but have a subtle difference.
  Normally, stubs are compiled into object files and linked against object files generated from `moonc`-generated C source files.
  This linking is only controlled by `cc-flags` and `cc-link-flags`, as mentioned earlier.
  However, in specific modes, such as when the fast-debugging-test feature is enabled,
  there will be a separate linking procedure for stub objects files, where
  `stub-cc-link-flags` will take effect.

#### Default C compiler and compiler flags for the native backend

Here is a brief summarization to [compiler_flags.rs](https://github.com/moonbitlang/moon/blob/main/crates/moonutil/src/compiler_flags.rs)

##### C Compiler

Search in PATH for the following items from top to bottom.

- cl
- gcc
- clang
- cc
- the internal tcc

For GCC-like compilers, the default compile & link command is as follows.
`[]` is used to indicate the flags may not exist in some modes.

```shell
cc -o $target -I$MOON_HOME/include -L$MOON_HOME/lib [-g] [-shared -fPIC] \
   -fwrapv -fno-strict-aliasing (-O2|-Og) [$MOON_HOME/lib/libmoonbitrun.o] \
   $sources -lm $cc_flags $cc_link_flags
```

For MSVC, the default compile & link command is as follows.

```shell
cl (/Fo|/Fe)$target -I$MOON_HOME/include [/LD] /utf-8 /wd4819 /nologo (/O2|/Od) \
   /link /LIBPATH:$MOON_HOME/lib
```

## Pre-build

The `"pre-build"` field is used to specify pre-build commands, which will be executed before build commands such as `moon check|build|test`.

`"pre-build"` is an array, where each element is an object containing `input`, `output`, and `command` fields. The `input` and `output` fields can be strings or arrays of strings, while the `command` field is a string. In the `command`, you can use any shell commands, as well as the `$input` and `$output` variables, which represent the input and output files, respectively. If these fields are arrays, they will be joined with spaces by default.

Currently, there is a built-in special command `:embed`, which converts files into MoonBit source code. The `--text` parameter is used to embed text files, and `--binary` is used for binary files. `--text` is the default and can be omitted. The `--name` parameter is used to specify the generated variable name, with `resource` being the default. The command is executed in the directory where the `moon.pkg.json` file is located.

### moon.pkg

```moonbit
options(
  "pre-build": [
    {
      "input": "a.txt",
      "output": "a.mbt",
      "command": ":embed -i $input -o $output",
    },
  ],
)
```

### moon.pkg.json

```json
{
  "pre-build": [
    {
      "input": "a.txt",
      "output": "a.mbt",
      "command": ":embed -i $input -o $output"
    }
  ]
}
```

If the content of `a.txt` in the current package directory is:

```default
hello,
world
```

After running `moon build`, the following `a.mbt` file will be generated in the directory where the `moon.pkg.json` is located:

```default
let resource : String =
  #|hello,
  #|world
  #|
```

## Warnings List

Used to disable warnings, enable warnings, or treat a warning as a fatal error.
The warning list is a string composed of multiple warning name, each prefixed with a sign:

- `-` to disable the warning
- `+` to enable the warning
- `@` to treat the enabled warning as a fatal error

For example, in the following configuration, `-unused_value` disables the unused functions and variables warning.

### moon.pkg

```moonbit
warnings = "-unused_value"
```

### moon.pkg.json

```json
{
  "warn-list": "-unused_value"
}
```

If multiple warnings need to be disabled, they can be directly connected and combined.

### moon.pkg

```moonbit
warnings = "-unused_value-unreachable_code"
```

### moon.pkg.json

```json
{
  "warn-list": "-unused_value-unreachable_code"
}
```

If it is necessary to activate certain warnings that were originally prohibited, use the plus sign.

### moon.pkg

```moonbit
warnings = "+unused_optional_argument"
```

### moon.pkg.json

```json
{
  "warn-list": "+unused_optional_argument"
}
```

To treat a warning as a fatal error, use the `@`.

### moon.pkg

```moonbit
warnings = "@deprecated"
```

### moon.pkg.json

```json
{
  "warn-list": "@deprecated"
}
```

You can also use warning numbers in `warn-list`. In the output below, `mnemonic`
is the symbolic warning name used in warning lists, while `id` is the numeric
form of the same warning.

The current list from `moonc check -warn-help` is:

```default
Available warnings:
mnemonic                   description                                                     id state
unused_value               Unused variable or function.                                     1 warn
unused_value               Unused variable.                                                 2 warn
unused_type_declaration    Unused type declaration.                                         3 warn
missing_priv               Unused abstract type.                                            4 warn
unused_type_variable       Unused type variable.                                            5 warn
unused_constructor         Unused constructor.                                              6 warn
unused_field               Unused field or constructor argument.                            7 warn
redundant_modifier         Redundant modifier.                                              8 warn
struct_never_constructed   Struct never constructed.                                        9 warn
unused_pattern             Unused pattern.                                                 10 warn
partial_match              Partial pattern matching.                                       11 error
unreachable_code           Unreachable code.                                               12 warn
unresolved_type_variable   Unresolved type variable.                                       13 warn
alert or alert_<category>  All alerts or alerts with specific category.                    14 warn
unused_mut                 Unused mutability.                                              15 error
parser_inconsistency       Parser inconsistency check.                                     16 warn
ambiguous_loop_argument    Ambiguous usage of loop argument.                               17 warn
useless_loop               Useless loop expression.                                        18 warn
deprecated                 Deprecated API usage.                                           20 warn
missing_pattern_arguments  Some arguments of constructor are omitted in pattern.           21 warn
ambiguous_block            Ambiguous block.                                                22 warn
unused_try                 Useless try expression.                                         23 warn
unused_error_type          Useless error type.                                             24 warn
test_unqualified_package   Using implicitly imported API in test.                          25 off
unused_catch_all           Useless catch all.                                              26 warn
deprecated_syntax          Deprecated syntax.                                              27 warn
todo                       Todo                                                            28 warn
unused_package             Unused package.                                                 29 warn
missing_package_alias      Empty package alias.                                            30 warn
unused_optional_argument   Optional argument never supplied.                               31 off
unused_default_value       Default value of optional argument never used.                  32 off
text_segment_excceed       Text segment exceed the line or column limits.                  33 warn
implicit_use_builtin       Implicit use of definitions from `moonbitlang/core/builtin`.    34 warn
reserved_keyword           Reserved keyword.                                               35 warn
loop_label_shadowing       Loop label shadows another label.                               36 warn
unused_loop_label          Unused loop label.                                              37 warn
missing_invariant          For-loop is missing an invariant.                               38 off
missing_reasoning          For-loop is missing a proof_reasoning.                          39 off
multiline_string_escape    Deprecated escape sequence in multiline string.                 40 error
missing_rest_mark          Missing `..` in map pattern.                                    41 warn
invalid_attribute          Invalid attribute.                                              42 warn
unused_attribute           Unused attribute.                                               43 warn
invalid_inline_wasm        Invalid inline-wasm.                                            44 error
unused_rest_mark           Useless `..` in pattern                                         46 warn
invalid_mbti               Invalid mbti file                                               47 warn
missing_definition         Unused pub definition because it does not exist in mbti file.   49 warn
method_shadowing           Local method shadows upstream method                            50 warn
ambiguous_precedence       Ambiguous operator precedence                                   51 warn
unused_loop_variable       Loop variable not updated in loop                               52 warn
unused_trait_bound         Unused trait bound                                              53 warn
ambiguous_range_direction  Ambiguous looping direction for range e1..=e2                   54 off
unannotated_ffi            Unannotated FFI param type                                      55 error
missing_pattern_field      Missing field in struct pattern                                 56 warn
missing_pattern_payload    Constructor pattern expect payload                              57 warn
unaligned_byte_access      Unaligned byte access in bits pattern                           59 warn
unused_struct_update       Unused struct update                                            60 warn
duplicate_test             Duplicate test name                                             61 warn
invalid_cascade            Calling method with non-unit return type via `..`               62 warn
syntax_lint                Syntax lint warning                                             63 warn
unannotated_toplevel_array Unannotated toplevel array                                      64 warn
prefer_readonly_array      Suggest ReadOnlyArray for read-only array literal               65 off
prefer_fixed_array         Suggest FixedArray for mutated array literal                    66 off
unused_async               Useless `async` annotation                                      67 warn
declaration_unimplemented  Declaration is unimplemented                                    68 warn
declaration_implemented    Declaration is already implemented                              69 off
deprecated_for_in_method   using `iterator()` method for `for .. in` loop.                 70 off
core_package_not_imported  Packages in `moonbitlang/core` need to be explicitly imported.  71 warn
unqualified_local_using    unqualified local using                                         72 off
unnecessary_annotation     unnecessary type annotation                                     73 off
missing_doc                Missing documentation for public definition                     74 off
A                          all warnings
state: warn = enabled, error = promoted to error, off = disabled
note: default alert exceptions: alert_unsafe=off
```

#### NOTE
Use `moonc check -warn-help` to see the list of preset compiler warnings.

### Alert Warning

Alerts are special warnings that indicate the usage of API marked with
[`#internal` attribute](../../language/attributes.md#internal-attribute).

All alerts has a category associated with it, which is customized by the author of the API.
You can enable or disable specific alert categories using the `alert_<category>` warning name,
or use `alert` to control all alert warnings at once.

For example, in the following configuration, all warnings for alerts are treated
as fatal errors, except for the `unsafe` category, which is disabled.

### moon.pkg

```moonbit
warnings = "@alert-alert_unsafe" 
```

### moon.pkg.json

```json
{
  "warn-list": "@alert-alert_unsafe" 
}
```

## Virtual Package

A virtual package serves as an interface of a package that can be replaced by actual implementations.

### Declarations

The `virtual` field is used to declare the current package as a virtual package.

For example, the following declares a virtual package with default implementation:

### moon.pkg

```moonbit
options(
  virtual: {
    "has-default": true,
  },
)
```

### moon.pkg.json

```json
{
  "virtual": {
    "has-default": true
  }
}
```

### Implementations

The `implement` field is used to declare the virtual package to be implemented by the current package.

For example, the following implements a virtual package:

### moon.pkg

```moonbit
options(
  implement: "moonbitlang/core/abort",
)
```

### moon.pkg.json

```json
{
  "implement": "moonbitlang/core/abort"
}
```

### Overriding implementations

The `overrides` field is used to provide the implementations that fulfills an imported virtual package.

For example, the following overrides the default implementation of the builtin abort package with another package:

### moon.pkg

```moonbit
options(
  overrides: [ "moonbitlang/dummy_abort/abort_show_msg" ],
)
```

### moon.pkg.json

```json
{
  "overrides": ["moonbitlang/dummy_abort/abort_show_msg"]
}
```
