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

Core packages are not special here: if you use `@json`, `@test`, or other core
aliases, add the corresponding `moonbitlang/core/...` package to `import` to
avoid `core_package_not_imported` warnings.

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

## Link Options

By default, moon only links packages where `is-main` is set to `true`. If you need to link other packages, you can specify this with the `link` option.

The `link` option is used to specify link options, and its value can be either a boolean or an object.

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

You can also use warnings number in warning list. Here is the full list of warning names:

```default
Available warnings:
    name                           description
  1 unused_value                   Unused variable or function.
  2 unused_value                   Unused variable.
  3 unused_type_declaration        Unused type declaration.
  4 missing_priv                   Unused abstract type.
  5 unused_type_variable           Unused type variable.
  6 unused_constructor             Unused constructor.
  7 unused_field                   Unused field or constructor argument.
  8 redundant_modifier             Redundant modifier.
  9 struct_never_constructed       Struct never constructed.
 10 unused_pattern                 Unused pattern.
 11 partial_match                  Partial pattern matching.
 12 unreachable_code               Unreachable code.
 13 unresolved_type_variable       Unresolved type variable.
 14 alert or alert_<category>      All alerts or alerts with specific category.
 15 unused_mut                     Unused mutability.
 16 parser_inconsistency           Parser inconsistency check.
 17 ambiguous_loop_argument        Ambiguous usage of loop argument.
 18 useless_loop                   Useless loop expression.
 19 toplevel_not_left_aligned      Top_level declaration is not left aligned.
 20 deprecated                     Deprecated API usage.
 21 missing_pattern_arguments      Some arguments of constructor are omitted in pattern.
 22 ambiguous_block                Ambiguous block.
 23 unused_try                     Useless try expression.
 24 unused_error_type              Useless error type.
 25 test_unqualified_package       Using implicitly imported API in test.
 26 unused_catch_all               Useless catch all.
 27 deprecated_syntax              Deprecated syntax.
 28 todo                           Todo
 29 unused_package                 Unused package.
 30 missing_package_alias          Empty package alias.
 31 unused_optional_argument       Optional argument never supplied.
 32 unused_default_value           Default value of optional argument never used.
 33 text_segment_excceed           Text segment exceed the line or column limits.
 34 implicit_use_builtin           Implicit use of definitions from `moonbitlang/core/builtin`.
 35 reserved_keyword               Reserved keyword.
 36 loop_label_shadowing           Loop label shadows another label.
 37 unused_loop_label              Unused loop label.
 38 missing_invariant              For-loop is missing an invariant.
 39 missing_reasoning              For-loop is missing a reasoning.
 41 missing_rest_mark              Missing `..` in map pattern.
 42 invalid_attribute              Invalid attribute.
 43 unused_attribute               Unused attribute.
 44 invalid_inline_wasm            Invalid inline-wasm.
 46 unused_rest_mark               Useless `..` in pattern
 47 invalid_mbti                   Invalid mbti file
 48 missing_default_impl_mark      Trait method with default implementation not marked with `= _`
 49 missing_definition             Unused pub definition because it does not exist in mbti file.
 50 method_shadowing               Local method shadows upstream method
 51 ambiguous_precedence           Ambiguous operator precedence
 52 unused_loop_variable           Loop variable not updated in loop
 53 unused_trait_bound             Unused trait bound
 55 unannotated_ffi                Unannotated FFI param type
 56 missing_pattern_field          Missing field in struct pattern
 57 missing_pattern_payload        Constructor pattern expect payload
 58 unused_non_capturing           Unnecessary non-capturing group in regex
 59 unaligned_byte_access          Unaligned byte access in bits pattern
 60 unused_struct_update           Unused struct update
 61 duplicate_test                 Duplicate test name
 62 invalid_cascade                Calling method with non-unit return type via `..`
 63 syntax_lint                    Syntax lint warning
 64 unannotated_toplevel_array     Unannotated toplevel array
 65 prefer_readonly_array          Suggest ReadOnlyArray for read-only array literal
 66 prefer_fixed_array             Suggest FixedArray for mutated array literal
 67 unused_async                   Useless `async` annotation
 68 declaration_unimplemented      Declaration is unimplemented
 69 declaration_implemented        Declaration is already implemented
 70 deprecated_for_in_method       using `iterator()` method for `for .. in` loop.
  A                                all warnings
```

#### NOTE
Use `moonc build-package -warn-help` to see the list of preset compiler warnings.

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
