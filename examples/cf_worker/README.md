## Moonbit's Cloudflare Worker Demo

This project showcases how to generate a compact WebAssembly (Wasm) by Moonbit, and invoke it from JavaScript in a Cloudflare worker environment. It is an implementation of the [Invoke Wasm from JavaScript](https://developers.cloudflare.com/workers/runtime-apis/webassembly/javascript/) guide.

## Setup Wrangler

Before you begin, make sure you have `node` and `pnpm` (or `npm`) installed.

To set up a new project, just run `pnpm create cloudflare@2.5.0` and answer the prompts:
- Application Type: Select "Hello World" worker.
- Use TypeScript: Select 'yes'.
- Deploy Your Application: Select 'no'.

## Adding MoonBit

Create the three following files (`moon.mod.json` `moon.pkg.json` `top.mbt`) to the directory just created

```json title=moon.mod.json
{
  "name": "username/hello",
  "version": "0.1.0"
}
```

```json title=moon.pkg.json
{
  "link": {
    "wasm-gc": {
      "exports": [ "fib" ]
    }
  }
}
```

```moonbit title=top.mbt
pub fn fib(n : Int) -> Int64 {
  loop 0L, 1L, n {
    a, _, 0 => a
    a, b, n => continue b, a + b, n - 1
  }
}
```

This will export a function named `fib` with the wasm-gc backend.

## Integrate MoonBit to worker
- Add the following to the `src/index.ts`
  ```typescript title=src/index.ts
  import wasm from '../target/wasm-gc/release/build/hello.wasm';
  const module = await WebAssembly.instantiate(wasm);
  module.exports._start();

  export interface Env {}

  export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
      return new Response(`Hello World! ${module.exports.fib(10)}`);
    }
  };
  ```
- Modify the `start` script in `package.json` to `"start": "moon build --target wasm-gc && wrangler dev",`.
- Append the following to `.gitignore`:

  ```gitignore
  # MoonBit project
  
  target/
  .mooncakes/
  ```

## Run the Worker

Navigate to your Cloudflare worker's directory (e.g., `moonbit_cf`) and use Wrangler to start the development server.

Run `pnpm i` to install the dependencies and `pnpm start`, and you should see output indicating the server is running, like this:

```shell
> your-project@0.0.0 start /your-path/moonbit-docs/examples/cf_worker
> moon build --target wasm-gc && wrangler dev

moon: no work to do
 ⛅️ wrangler 3.48.0
-------------------
⎔ Starting local server...
[wrangler:inf] Ready on http://localhost:58966
```

Then you can use `b` to open a browser or `x` to exit the server. The bowser should give you `Hello World! 55`;
