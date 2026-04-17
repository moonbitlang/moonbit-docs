# Module Configuration

moon uses the `moon.mod.json` file to identify and describe a module.

## Name

The `name` field is used to specify the name of the module, and it is required.

```json
{
  "name": "example"
  // ...
}
```

The module name can contain letters, numbers, `_`, `-`, and `/`.

For modules published to [mooncakes.io](https://mooncakes.io), the module name must begin with the username. For example:

```json
{
  "name": "moonbitlang/core"
  // ...
}
```

## Version

The `version` field is used to specify the version of the module.

This field is optional. For modules published to [mooncakes.io](https://mooncakes.io), the version number must follow the [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) specification.

```json
{
  "name": "example",
  "version": "0.1.0"
  // ...
}
```

## Dependency Management

The `deps` field is used to specify the dependencies of the module.

It is automatically managed by commands like `moon add` and `moon remove`.

```json
{
  "name": "username/hello",
  "deps": {
    "moonbitlang/x": "0.4.6"
  }
}
```

You may also specify a local dependency, such as:

```json
{
  "name": "username/hello",
  "deps": {
    "username/other": {
      "path": "../other"
    }
  }
}
```

## Meta Information

### README

The `readme` field is used to specify the path to the module's README file.

### Repository

The `repository` field is used to specify the URL of the module's repository.

### License

The `license` field is used to specify the license of the module. The license type must comply with the [SPDX License List](https://spdx.org/licenses/).

```json
{
  "license": "MIT"
}
```

### Keywords

The `keywords` field is used to specify the keywords for the module.

```json
{
  "keywords": ["example", "test"]
}
```

### Description

The `description` field is used to specify the description of the module.

```json
{
  "description": "This is a description of the module."
}
```

## Include and Exclude

The `include` and `exclude` fields are used to include or exclude specific directories or files during publishing process.

It follows the gitignore syntax, and include follows the exclude.
For example, the following configuration will include the `build/assets`
but exclude anything else in the `build` directory.

```json
{
  "exclude": ["build"],
  "include": ["build/assets"]
}
```

You may use [`moon package --list`](commands.md#moon-package) to verify if the packaged result is expected.

## Preferred Target

The `preferred-target` field allows the `moon` and the language server to know which target
should be used as the default target, avoiding the necessity to write `--target`
when developing a project targeting other backends than Wasm GC.

```json
{
  "preferred-target": "js"
}
```

## Supported Targets

The `supported-targets` field declares which backends this module is intended to support.
Unlike `preferred-target`, it does not choose a default target for commands. Use it to record
the module's compatibility surface in metadata.

`supported-targets` uses a compact target-set syntax:

- `js` for a single backend
- `+js+wasm-gc` for an explicit set of backends
- `+all-js` for all backends except `js`

For example:

```json
{
  "supported-targets": "+js+wasm-gc"
}
```

Legacy array syntax is still accepted for compatibility:

```json
{
  "supported-targets": ["js", "native"]
}
```

`preferred-target` and `supported-targets` are often used together:

- `preferred-target` says which backend `moon` should use by default
- `supported-targets` says which backends the module claims to support

When a package also defines `supported-targets`, the effective backend set is the intersection
of the module-level and package-level declarations.

For per-file conditional compilation inside a package, use [`targets`](package.md#conditional-compilation)
in `moon.pkg` / `moon.pkg.json` instead.

## Source directory

The `source` field is used to specify the source directory of the module.

It must be a subdirectory of the directory where the `moon.mod.json` file is located and must be a relative path.

When creating a module using the `moon new` command, a `src` directory will be automatically generated, and the default value of the `source` field will be `src`.

```json
{
  "source": "src"
}
```

When the `source` field does not exist, or its value is `null` or an empty string `""`, it is equivalent to setting `"source": "."`. This means that the source directory is the same as the directory where the `moon.mod.json` file is located.

```json
{
  "source": null
}
{
  "source": ""
}
{
  "source": "."
}
```

## Warning List

This is used to disable specific preset compiler warning numbers.

For example, in the following configuration, `-2` disables the warning number 2 (Unused variable).

```json
{
  "warn-list": "-2"
}
```

If multiple warnings need to be disabled, they can be directly connected and combined.

```json
{
  "warn-list": "-2-4"
}
```

If it is necessary to activate certain warnings that were originally prohibited, use the plus sign.

```json
{
  "warn-list": "+31"
}
```

You can use `moonc check -warn-help` to see the list of preset compiler warning numbers.
In the output below, `mnemonic` is the symbolic warning name used in warning lists,
while `id` is the numeric form of the same warning.

```default
$ moonc check -warn-help
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

## Scripts

The `scripts` field is used to define custom scripts associated with the module.

### postadd script

The `postadd` script runs automatically after the module has been added.
When executed, the script's current working directory (cwd) is set to the
directory where the `moon.mod.json` file resides.

```json
{
  "scripts": {
    "postadd": "python3 build.py"
  }
}
```

### [Experimental] Pre-build config script

#### WARNING
This feature is extremely experimental, and its API may change at any time.
This documentation reflects the implementation as of 2025-06-03.

#### IMPORTANT
Using this feature may execute arbitrary code in your computer.
Please use with caution and only with trusted dependencies.

The pre-build config script is added in order to aid native target programming.
To use such script, add your script in your `moon.mod.json`:

```json
{
  "--moonbit-unstable-prebuild": "<path/to/build-script>"
}
```

The path is a relative path from the root of the project. The script may either
be a JavaScript script (with extension `.js`, `.cjs`, `.mjs`) executed with
`node`, or a Python script (with extension `.py`) executed with `python3` or
`python`.

#### Input

The script will be provided with a JSON with the structure of
`BuildScriptEnvironment` from standard input stream (stdin):

```ts
/** Represents the environment a build script receives */
interface BuildScriptEnvironment {
  env: Record<string, string>
  paths: Paths
}

interface BuildInfo {
  /** The target info for the build script currently being run. */
  host: TargetInfo
  /** The target info for the module being built. */
  target: TargetInfo
}

interface TargetInfo {
  /** The actual backend we're using, e.g. `wasm32`, `wasmgc`, `js`, `c`, `llvm` */
  kind: string // TargetBackend
}
```

#### Output

The script is expected to print a JSON string in its standard output stream
(stdout) with the structure of `BuildScriptOutput`:

```ts
interface BuildScriptOutput {
  /** Build variables */
  vars?: Record<string, string>
  /** Configurations to linking */
  link_configs?: LinkConfig[]
}

interface LinkConfig {
  /** The name of the package to configure */
  package: string

  /** Link flags that needs to be propagated to dependents
   *
   * Reference: `cargo::rustc-link-arg=FLAG` */
  link_flags?: string

  /** Libraries that need linking, propagated to dependents
   *
   * Reference: `cargo::rustc-link-lib=LIB` */
  link_libs?: string[]

  /** Paths that needs to be searched during linking, propagated to dependents
   *
   * Reference: `cargo::rustc-link-search=[KIND=]PATH` */
  link_search_paths?: string[]
}
```

#### Build variables

You may use the variables emitted in the `vars` fields in the native linking
arguments in `moon.pkg` as `${build.<var_name>}`.

For example, if your build script outputs:

```json
{ "vars": { "CC": "gcc" } }
```

and your `moon.pkg` is structured like:

```text
options(
  link: {
    "native": {
      "cc": "${build.CC}",
    },
  },
)
```

It will be transformed into

```json
{
  "link": {
    "native": {
      "cc": "gcc"
    }
  }
}
```
