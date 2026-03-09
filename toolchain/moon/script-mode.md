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
  let xs = @ls.from_array(["1", "2", "3"])
  debug(xs)
}
```

Then run this script directly:

```default
$ moon run script.mbtx
```

In `.mbtx`, you can declare imports at the top of the file using the same syntax as package
configuration. There is one difference: import paths can optionally include a version
`@version` after the module name:

```mbt
///|
import {
  "moonbitlang/async@0.16.5/fs",
  "moonbitlang/async@0.16.5",
}

///|
async fn main {
  ...
}
```

All imported packages from the same module must use the same version.

If the import path is not explicitly versioned, it uses the latest version
in the local registry index.

## Run a `.mbtx` script from stdin

Moon supports running a `.mbtx` script from stdin:

```default
$ cat script.mbtx | moon run -
```

You can also use a heredoc, a feature provided by the shell:

```default
$ moon run - <<EOF
fn main {
  println("hello")
}
EOF
```
