# Package Configuration

moon uses the `moon.pkg.json` file to identify and describe a package.

## Name

The package name is not configurable; it is determined by the directory name of the package.

## is-main

The `is-main` field is used to specify whether a package needs to be linked into an executable file.

The output of the linking process depends on the backend. When this field is set to `true`:

- For the `wasm` and `wasm-gc` backends, a standalone WebAssembly module will be generated.
- For the `js` backend, a standalone JavaScript file will be generated.

## import

The `import` field is used to specify other packages that a package depends on.

## test-import

The `test-import` field is used to specify other packages that the black-box test package of this package depends on.

## wbtest-import

The `wbtest-import` field is used to specify other packages that the white-box test package of this package depends on.

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

  ```json
  {
    "link": true
  }
  ```

- When the `link` value is an object, it indicates that the package should be linked, and you can specify link options. For detailed configuration, please refer to the subpage for the corresponding backend.

### Wasm Backend Link Options

#### Configurable Options

- The `exports` option is used to specify the function names exported by the `wasm` backend.

  For example, in the following configuration, the `hello` function from the current package is exported as the `hello` function in the `wasm` module, and the `foo` function is exported as the `bar` function in the `wasm` module. In the `wasm` host, the `hello` and `bar` functions can be called to invoke the `hello` and `foo` functions from the current package.

  ```json
  {
    "link": {
      "wasm": {
        "exports": [
          "hello",
          "foo:bar"
        ]
      }
    }
  }
  ```

- The `heap-start-address` option is used to specify the starting address of the linear memory that can be used when compiling to the `wasm` backend.

  For example, the following configuration sets the starting address of the linear memory to 1024.

  ```json
  {
    "link": {
      "wasm": {
        "heap-start-address": 1024
      }
    }
  }
  ```

- The `import-memory` option is used to specify the linear memory imported by the `wasm` module.

  For example, the following configuration specifies that the linear memory imported by the `wasm` module is the `memory` variable from the `env` module.

  ```json
  {
    "link": {
      "wasm": {
        "import-memory": {
          "module": "env",
          "name": "memory"
        }
      }
    }
  }
  ```

- The `export-memory-name` option is used to specify the name of the linear memory exported by the `wasm` module.

  ```json
  {
    "link": {
      "wasm": {
        "export-memory-name": "memory"
      }
    }
  }
  ```

### Wasm GC Backend Link Options

The link options for the `wasm-gc` backend are similar to those for the `wasm` backend, except there is no `heap-start-address` option.

### JS Backend Link Options

#### Configurable Options

- The `exports` option is used to specify the function names to export in the JavaScript module.

  For example, in the following configuration, the `hello` function from the current package is exported as the `hello` function in the JavaScript module. In the JavaScript host, the `hello` function can be called to invoke the `hello` function from the current package.

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
  - `esm`
  - `cjs`
  - `iife`

  For example, the following configuration sets the output format of the current package to ES Module.

  ```json
  {
    "link": {
      "js": {
        "format": "esm"
      }
    }
  }
  ```

## Pre-build

The `"pre-build"` field is used to specify pre-build commands, which will be executed before build commands such as `moon check|build|test`.

`"pre-build"` is an array, where each element is an object containing `input`, `output`, and `command` fields. The `input` and `output` fields can be strings or arrays of strings, while the `command` field is a string. In the `command`, you can use any shell commands, as well as the `$input` and `$output` variables, which represent the input and output files, respectively. If these fields are arrays, they will be joined with spaces by default.

Currently, there is a built-in special command `:embed`, which converts files into MoonBit source code. The `--text` parameter is used to embed text files, and `--binary` is used for binary files. `--text` is the default and can be omitted. The `--name` parameter is used to specify the generated variable name, with `resource` being the default. The command is executed in the directory where the `moon.pkg.json` file is located.

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
```
hello,
world
```

After running `moon build`, the following `a.mbt` file will be generated in the directory where the `moon.pkg.json` is located:

```
let resource : String =
  #|hello,
  #|world
  #|
```

## Warning List

This is used to disable specific preset compiler warning numbers.

For example, in the following configuration, `-2` disables the warning number 2 (Unused variable).

```json
{
  "warn-list": "-2",
}
```

You can use `moonc build-package -warn-help` to see the list of preset compiler warning numbers.

```
$ moonc -v                      
v0.1.20240914+b541585d3

$ moonc build-package -warn-help
Available warnings: 
  1 Unused function.
  2 Unused variable.
  3 Unused type declaration.
  4 Redundant case in a pattern matching (unused match case).
  5 Unused function argument.
  6 Unused constructor.
  7 Unused module declaration.
  8 Unused struct field.
 10 Unused generic type variable.
 11 Partial pattern matching.
 12 Unreachable code.
 13 Unresolved type variable.
 14 Lowercase type name.
 15 Unused mutability.
 16 Parser inconsistency.
 18 Useless loop expression.
 19 Top-level declaration is not left aligned.
 20 Invalid pragma
 21 Some arguments of constructor are omitted in pattern.
 22 Ambiguous block.
 23 Useless try expression.
 24 Useless error type.
 26 Useless catch all.
  A all warnings
```

## Alert List

Disable user preset alerts.

```json
{
  "alert-list": "-alert_1-alert_2"
}
```