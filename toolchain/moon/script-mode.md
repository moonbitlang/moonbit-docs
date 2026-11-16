# Running `.mbtx` Scripts

The Moon build system lets you write script files in MoonBit without any module or package
configuration files. Script files use the special `.mbtx` extension.

## Run a `.mbtx` file

Write a script `script.mbtx`:

```mbt
---
import {
  "moonbitlang/core/list" @ls
}
---

///|
async fn main {
  let xs = @ls.List(["1", "2", "3"])
  debug(xs)
}
```

Then run this script directly:

```none
$ moon run script.mbtx
```

You can also use `moonx script.mbtx`; see
[Running Scripts and Tools with `moonx`](https://docs.moonbitlang.com/en/latest/toolchain/moon/moonx.html).

In `.mbtx`, declare imports in frontmatter enclosed by `---` lines at the
beginning of the file, using the same syntax as package configuration.
Imports outside frontmatter are deprecated (`unfenced_import`, warning 96).
For example, an async script can import the standard library's
`moonbitlang/core/async` package in frontmatter:

```moonbit
---
import {
  "moonbitlang/core/async",
}
---

///|
async fn main {
  @async.sleep(0)
  println("done")
}
```

Run this example with `moon run --target native async.mbtx`.

#### NOTE
Running this script currently reports an experimental-package warning.
Unlike `moon.pkg`, script frontmatter does not support the
`options("allow-experimental-packages": true)` opt-in. The warning does not
prevent the script from running.

For third-party dependencies, import paths can optionally include a version
`@version` after the module name, in the form `author/module@version/package`.
All imported packages from the same module must use the same version.

If the import path is not explicitly versioned, it uses the latest version
in the local registry index.

Standard library imports such as `moonbitlang/core/async` use the version
bundled with the toolchain and do not need a version in the import path.

A script may add `*` after an import to bring all definitions from that package
into its scope. The import may also set a custom package alias with `@alias`:

```moonbit
---
import {
  "moonbitlang/core/queue" @q *
}
---

///|
fn main {
  let queue = Queue([1, 2, 3])
  println(queue.length())
  let qualified = @q.Queue([4, 5])
  println(qualified.length())
}
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

```none
$ cat script.mbtx | moon run -
```

For short scripts, pass the `.mbtx` source directly with `-c`:

```none
$ moon run -c "<script>"
$ moon run -c 'fn main { println("hello") }'
```

You can also use a heredoc, a feature provided by the shell:

```none
$ moon run - <<EOF
fn main {
  println("hello")
}
EOF
```
