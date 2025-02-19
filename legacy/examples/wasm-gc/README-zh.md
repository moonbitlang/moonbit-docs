# MoonBit WebAssembly 垃圾回收（Wasm GC）说明

## 依赖项

此示例在以下版本的环境中可正常运行。

```bash
moon 0.1.0 (dff5fcc 2023-11-05)
moonc 5258d5b95 ~/.moon/bin/moonc
chrome version 119
```

## 运行方法

### 在浏览器中运行

```bash
moon build --target wasm-gc
python3 -m http.server 8080 # 或者使用其他方式启动一个服务器
```

启动服务器后，访问 http://localhost:8080/index.html，带有 WebAssembly 垃圾回收功能的 MoonBit 程序将在浏览器中运行。

### 在 Deno 中运行

```bash
moon build --target wasm-gc
deno run --allow-read main.mjs # 需要 --allow-read 权限才能从路径加载 WebAssembly 模块
```

### 在 Node（版本 >= 22.0.0）中运行

```bash
moon build --target wasm-gc
node main.mjs
```
