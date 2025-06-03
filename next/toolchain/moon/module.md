# Module Configuration

moon uses the `moon.mod.json` file to identify and describe a module. For full JSON schema, please check [moon's repository](https://github.com/moonbitlang/moon/blob/main/crates/moonbuild/template/mod.schema.json).

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

## Deps

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

## README

The `readme` field is used to specify the path to the module's README file.

## Repository

The `repository` field is used to specify the URL of the module's repository.

## License

The `license` field is used to specify the license of the module. The license type must comply with the [SPDX License List](https://spdx.org/licenses/).

```json
{
  "license": "MIT"
}
```

## Keywords

The `keywords` field is used to specify the keywords for the module.

```json
{
  "keywords": ["example", "test"]
}
```

## Description

The `description` field is used to specify the description of the module.

```json
{
  "description": "This is a description of the module."
}
```

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

You can use `moonc build-package -warn-help` to see the list of preset compiler warning numbers.

```
$ moonc -v
v0.1.20250318+35770a65e

$ moonc build-package -warn-help
Available warnings:
  1 Unused function.
  2 Unused variable.
  3 Unused type declaration.
  4 Unused abstract type.
  5 Unused type variable.
  6 Unused constructor.
  7 Unused field or constructor argument.
  8 Redundant modifier.
  9 Unused function declaration.
 10 Struct never constructed.
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
 27 Deprecated syntax.
 28 Todo
 29 Unused package.
 30 Empty package alias.
 31 Optional argument never supplied.
 32 Default value of optional argument never used.
 33 Unused import value
 35 Reserved keyword.
 36 Loop label shadows another label.
 37 Unused loop label.
 38 Useless guard.
 39 Duplicated method.
 40 Call a qualified method using regular call syntax.
 41 Closed map pattern.
 42 Invalid attribute.
 43 Unused attribute.
 44 Invalid inline-wasm.
 45 Type implements trait with regular methods.
  A all warnings
```

## Alert List

Disable user preset alerts.

```json
{
  "alert-list": "-alert_1-alert_2"
}
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

## \[Experimental\] Pre-build config script

:::{info}
This feature is extremely experimental, and its API may change at any time.
This documentation reflects the implementation as of 2025-06-03.
:::

:::{important}
Using this feature may execute arbitrary code in your computer.
Please use with caution and only with trusted dependencies.
:::

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

### Input

The script will be provided with a JSON with the structure of
`BuildScriptEnvironment`:

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

  // The following fields are not properly populated now:

  /** The architecture of the target. This is either the architecture in the
   * target triple like `x86_64` and `aarch64`, or one of our other
   * non-native backends like `js`, `wasm32` and `wasmgc`. */
  arch: string
  /** The vendor of the target. This is often `unknown`. */
  vendor: string
  /** The operating system of the target. This is often `linux`, `windows` or `macos`. */
  os: string
  /** The ABI of the target. Might be null, or something like `gnu`, `musl`,
   * `msvc`, `eabi` and similar. */
  abi?: string
  /** The target triple, e.g. `x86_64-unknown-linux-gnu`. */
  triplet: string
}
```

### Output

The script is expected to print a JSON string in its stdout with the structure
of `BuildScriptOutput`:

```ts
interface BuildScriptOutput {
  /** Rerun conditions. **DOES NOT WORK NOW** */
  rerun_if?: RerunIfKind[]
  // TODO: How much of these vars are useful? We don't fetch link flags from
  // here any more. However, they might still be useful for future
  // match-replace in code.
  // TODO: what about array-like vars? like commandline args
  vars?: Record<string, string>
  /** Configurations to linking */
  link_configs?: LinkConfig[]
}

// Does not work now
type RerunIfKind =
  /** Rerun if the file at the given path changes. */
  | { File: string }
  /** Rerun if the directory at the given path changes. */
  | { Dir: string }
  /** Rerun if the environment variable with the given name changes. */
  | { Env: string }

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

### Build variables

You may use the variables emitted in `$.vars` in native linking arguments in
`moon.pkg.json` as `${build.<var_name>}`.

For example, if your build script outputs:

```json
{ "vars": { "CC": "gcc" } }
```

and your `moon.pkg.json` is structured like:

```json
{
  "link": {
    "native": {
      "cc": "${build.CC}"
    }
  }
}
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
