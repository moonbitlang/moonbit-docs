# Running `.mbtx` Scripts

The Moon build system lets you write script files in MoonBit without any module or package
configuration files. Script files use the special `.mbtx` extension.

## Run a `.mbtx` file

Write a script `script.mbtx`:

```mbt
///|
import {
  "moonbitlang/core/list" @ls
}

///|
async fn main {
  let xs = @ls.List(["1", "2", "3"])
  debug(xs)
}
```

Then run this script directly:

```
$ moon run script.mbtx
```

In `.mbtx`, you can declare imports at the top of the file using the same syntax as package
configuration. There is one difference: import paths can optionally include a version
`@version` after the module name:

```mbt
///|
import {
  "moonbitlang/async@0.20.2/fs",
  "moonbitlang/async@0.20.2",
}

///|
async fn main {
  ...
}
```

All imported packages from the same module must use the same version.

If the import path is not explicitly versioned, it uses the latest version
in the local registry index.

A script may add `*` after an import to bring all definitions from that package
into its scope. The import may also set a custom package alias with `@alias`:

```{literalinclude} /sources/script-mode/import-all.mbtx
:language: moonbit
```

The package alias remains available, so the example can use both `Queue` and
`@q.Queue`. Without an explicit `@alias`, the package's default alias is used.
Import-all syntax is limited to `.mbtx` scripts; regular packages should use
package aliases or `using` declarations. Prefer explicit imports when name
conflicts would make a script difficult to read.

## Test a `.mbtx` script

Pass a script path to `moon test` to test that script by itself:

```bash
moon test script.mbtx
```

The script must define `fn main`, but the generated test entrypoint does not
run it. An explicit `.mbtx` path selects only that script, even when it is
inside a project; conversely, package-wide test runs do not include `.mbtx`
scripts.

## Run a `.mbtx` script from stdin

Moon supports running a `.mbtx` script from stdin:

```
$ cat script.mbtx | moon run -
```

For short scripts, pass the `.mbtx` source directly with `-c`:

```
$ moon run -c "<script>"
$ moon run -c 'fn main { println("hello") }'
```

You can also use a heredoc, a feature provided by the shell:

```
$ moon run - <<EOF
fn main {
  println("hello")
}
EOF
```
