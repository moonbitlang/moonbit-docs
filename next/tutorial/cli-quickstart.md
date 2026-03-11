# Native CLI Quickstart

This quickstart shows a simple but proper MoonBit CLI layout:

- keep argument parsing and business logic in a library package
- keep `cmd/main` small
- use `moonbitlang/async` for native IO
- test the pure parts without touching the network

This example uses `moonbitlang/async`, which currently supports the native backend best.

## Create the project

Start with a normal MoonBit module:

```bash
moon new download_cli
cd download_cli
moon add moonbitlang/async
```

`argparse` is already part of the standard library, so this quickstart only adds `moonbitlang/async`.

Set the preferred target to native in `moon.mod.json` so `moon run` and `moon build` default to the backend that `moonbitlang/async` supports best:

```json
{
  "name": "username/download_cli",
  "version": "0.1.0",
  "deps": {
    "moonbitlang/async": "0.16.6"
  },
  "preferred-target": "native"
}
```

The final layout will look like this:

```text
download_cli
├── cmd
│   └── main
│       ├── main.mbt
│       └── moon.pkg
├── cli_test.mbt
├── config.mbt
├── download.mbt
├── moon.mod.json
└── moon.pkg
```

## Keep parsing in the library package

The root package defines the CLI contract. It owns the command shape and turns argv into a typed config value:

```{literalinclude} /sources/cli-quickstart/config.mbt
:language: moonbit
:start-after: start config
:end-before: end config
```

The package descriptor imports `argparse` from `moonbitlang/core` and the async libraries used by the implementation:

```{literalinclude} /sources/cli-quickstart/moon.pkg
:language: moonbit
```

## Put async IO behind one function

`run` performs the actual download. If `-o` is passed, it streams the body into a file. Otherwise it writes directly to stdout:

```{literalinclude} /sources/cli-quickstart/download.mbt
:language: moonbit
:start-after: start run
:end-before: end run
```

## Keep `main` thin

`cmd/main` should usually do only wiring: read argv, build config, and call the library entrypoint.

```{literalinclude} /sources/cli-quickstart/cmd/main/moon.pkg
:language: moonbit
```

```{literalinclude} /sources/cli-quickstart/cmd/main/main.mbt
:language: moonbit
:start-after: start main
:end-before: end main
```

## Run the command

Write the response body to stdout:

```bash
moon run cmd/main https://example.com/feed.xml
```

Write it to a file:

```bash
moon run cmd/main https://example.com/feed.xml -o feed.xml
```

Build a native binary:

```bash
moon build --target native
```

## Test the pure part

The parser and config shaping logic stay easy to test because they do not perform IO:

```{literalinclude} /sources/cli-quickstart/cli_test.mbt
:language: moonbit
```

Run the tests with:

```bash
moon test
```

When the CLI grows, keep following the same split:

- parse and validate inputs in the library package
- keep side effects in a small number of async functions
- keep `cmd/main` focused on wiring
