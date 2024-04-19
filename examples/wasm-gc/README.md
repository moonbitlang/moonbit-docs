# Illstration of MoonBit wasm gc

## Deps

This example works with the following versions of the environment.

```bash
moon 0.1.0 (dff5fcc 2023-11-05)
moonc 5258d5b95 ~/.moon/bin/moonc
chrome version 119
```

## How to run

### Browser

```bash
moon build --target wasm-gc
python3 -m http.server 8080 # or any thing else to start a server
```

Navigate to http://localhost:8080/index.html after launching the server, moonbit with wasm gc is running in the browser.

### Deno

```bash
moon build --target wasm-gc
deno run --allow-read main.mjs # allow-read is needed to load wasm module from path
```

### Node (version >= 22.0.0)

```bash
moon build --target wasm-gc
node main.mjs
```