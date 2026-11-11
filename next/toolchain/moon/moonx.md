# Running Scripts and Tools with `moonx`

`moonx` runs a local `.mbtx` script or an executable package from Mooncakes
without a separate `moon install` step. It is a separate command, not a
subcommand of `moon`.

## Run a local script

Given a `script.mbtx` file, run:

```bash
moonx script.mbtx
```

No `moon.mod` or `moon.pkg` is needed. See
[Running `.mbtx` Scripts](script-mode.md) for script syntax and imports.

Arguments after the script path are passed to the script:

```bash
moonx script.mbtx --help
```

Here, `--help` is an argument to the script. Use `moonx --help` to display
help for `moonx` itself.

## Run a Mooncakes package

Specify the executable package path and optionally a module version:

```bash
moonx user/module/package@1.2.3
```

Replace `user/module/package` and `1.2.3` with a published executable package
and an existing version. The version goes after the complete package path.
`moonx` obtains the package's Wasm executable from the registry and runs it;
this can require a download. Only run tools you trust.

- `@1.2.3` selects that exact version.
- `@latest` refreshes the registry index before choosing the latest version.
- Omitting the version uses the latest version already known to the local
  registry index, which may not be the newest published version.

As with scripts, arguments after the package coordinate are passed to the
program. For example:

```bash
moonx user/module/package@1.2.3 --help
```

## `moonx` or `moon run`?

Use `moonx` for standalone scripts and published command-line tools. It uses
the linear-memory Wasm backend (`wasm`), not `wasm-gc`, `js`, or `native`;
registry packages must provide a compatible Wasm executable.

Use [`moon run`](commands.md#moon-run) to build and run a package in the
project you are developing, including when selecting another backend.
`moon run script.mbtx` also runs a standalone script; `moonx` provides a
dedicated entry point for scripts and registry tools.
