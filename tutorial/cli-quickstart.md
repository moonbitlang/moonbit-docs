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

```moonbit
pub struct Config {
  url : String
  output : String?
} derive(Show, Eq)

///|
pub fn command() -> @argparse.Command {
  @argparse.Command::new(
    "moon-fetch",
    about="Download a URL to stdout or a file",
    options=[
      @argparse.OptionArg::new(
        "output",
        short='o',
        about="Write the response body to this file",
      ),
    ],
    positionals=[
      @argparse.PositionArg::new("url", about="HTTP or HTTPS URL to download"),
    ],
  )
}

///|
pub fn parse_config(argv : Array[String]) -> Config raise {
  let matches = @argparse.parse(command(), argv~)
  let values : Map[String, Array[String]] = matches.values
  guard values is { "url": [url, ..], "output"? : output_paths, .. } else {
    fail("missing url")
  }
  let output = match output_paths {
    Some([output, ..]) => Some(output)
    _ => None
  }
  { url, output }
}
```

The package descriptor imports `argparse` from `moonbitlang/core` and the async libraries used by the implementation:

```moonbit
import {
  "moonbitlang/core/argparse",
  "moonbitlang/async/fs",
  "moonbitlang/async/http",
  "moonbitlang/async/stdio",
}
```

## Put async IO behind one function

`run` performs the actual download. If `-o` is passed, it streams the body into a file. Otherwise it writes directly to stdout:

```moonbit
pub async fn run(config : Config) -> Unit {
  let (response, body) = @http.get_stream(config.url)
  defer body.close()

  guard response.code is (200..<300) else {
    fail("download failed: \{response.code} \{response.reason}")
  }

  match config.output {
    Some(path) => {
      let file = @fs.create(path, permission=0o644)
      defer file.close()
      file.write_reader(body)
      @stdio.stderr.write("saved \{config.url} to \{path}\n")
    }
    None => @stdio.stdout.write_reader(body)
  }
}
```

## Keep `main` thin

`cmd/main` should usually do only wiring: read argv, build config, and call the library entrypoint.

```moonbit
import {
  "moonbit-community/cli-quickstart-doc" @app,
  "moonbitlang/core/env",
  "moonbitlang/async",
}

options(
  "is-main": true,
)
```

```moonbit
async fn main {
  let config = @app.parse_config(@env.args())
  @app.run(config)
}
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

```moonbit
///|
test "parse config for stdout" {
  let config = parse_config(["https://example.com/feed.xml"])
  assert_eq(config.url, "https://example.com/feed.xml")
  assert_eq(config.output, None)
}

///|
test "parse config for file output" {
  let config = parse_config(["https://example.com/feed.xml", "-o", "feed.xml"])
  assert_eq(config.url, "https://example.com/feed.xml")
  guard config.output is Some(path) else { fail("expected an output path") }
  assert_eq(path, "feed.xml")
}
```

Run the tests with:

```bash
moon test
```

When the CLI grows, keep following the same split:

- parse and validate inputs in the library package
- keep side effects in a small number of async functions
- keep `cmd/main` focused on wiring
