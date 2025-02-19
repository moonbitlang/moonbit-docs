## Moonbit 的 Cloudflare Worker 示例

本项目展示了如何通过 Moonbit 生成一个紧凑的 WebAssembly（Wasm），并在 Cloudflare Worker 环境中从 JavaScript 调用它。这是对[从 JavaScript 调用 Wasm](https://developers.cloudflare.com/workers/runtime-apis/webassembly/javascript/)指南的一种实现。

## 配置 Wrangler

在开始之前，请确保你已经安装了 `node` 和 `pnpm`（或者 `npm`）。

要创建一个新项目，只需运行 `pnpm create cloudflare@2.5.0` 并按照提示操作：

- 应用类型：选择“Hello World” Worker。
- 是否使用 TypeScript：选择“是”。
- 是否部署应用：选择“否”。

## 添加 MoonBit

在刚刚创建的目录中创建以下三个文件（`moon.mod.json`、`moon.pkg.json`、`top.mbt`）

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
			"exports": ["fib"]
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

这将使用 wasm - gc 后端导出一个名为 `fib` 的函数。

## 将 MoonBit 集成到 Worker 中

- 在 `src/index.ts` 中添加以下内容

  ```typescript title=src/index.ts
  import wasm from '../target/wasm-gc/release/build/hello.wasm';
  const module = await WebAssembly.instantiate(wasm);
  module.exports._start();

  export interface Env {}

  export default {
  	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  		return new Response(`Hello World! ${module.exports.fib(10)}`);
  	},
  };
  ```

- 将 `package.json` 中的 `start` 脚本修改为 `"start": "moon build --target wasm-gc && wrangler dev",`。
- 在 `.gitignore` 中追加以下内容：

  ```gitignore
  # MoonBit 项目

  target/
  .mooncakes/
  ```

## 运行 Worker

导航到你的 Cloudflare Worker 目录（例如 `moonbit_cf`），并使用 Wrangler 启动开发服务器。

运行 `pnpm i` 安装依赖，然后运行 `pnpm start`，你应该会看到表明服务器正在运行的输出，如下所示：

```shell
> your-project@0.0.0 start /your-path/moonbit-docs/examples/cf_worker
> moon build --target wasm-gc && wrangler dev

moon: no work to do
 ⛅️ wrangler 3.48.0
-------------------
⎔ Starting local server...
[wrangler:inf] Ready on http://localhost:58966
```

然后你可以使用 `b` 打开浏览器，或者使用 `x` 退出服务器。浏览器应该会显示 `Hello World! 55`。
