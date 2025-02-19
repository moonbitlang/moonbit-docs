# WebAssembly 基准测试

你可以在https://moonbitlang.github.io/moonbit-docs/legacy/benchmark/fibonacci/ 在线体验这个基准测试，或者按照以下说明在本地搭建。

## 斐波那契数列

本文件夹将使用多种编程语言构建 WebAssembly，用于计算第 n 个斐波那契数，以进行基准测试。

### Moonbit

使用 Moonbit 的[在线代码编辑器](https://try.moonbitlang.com/) 或[构建工具](https://www.moonbitlang.com/download/) 将以下函数转换为 WebAssembly 文本格式（Wat）：

```
func fib(num : Int) -> Int {
  fn aux(n, acc1, acc2) {
    match n {
      0 => acc1
      1 => acc2
      _ => aux(n - 1, acc2, acc1 + acc2)
    }
  }

  aux(num, 0, 1)
}

pub func test(n : Int, count : Int) -> Int {
  let mut i = 0
  let mut res = 0
  while i < count {
    res = fib(n)
    i = i + 1
  }
  res
}
```

然后使用 WebAssembly 二进制工具包（WABT）中的[wat2wasm](https://github.com/WebAssembly/wabt) 将 WebAssembly 文本格式（.wat）转换为 WebAssembly 二进制格式（.wasm）：

```sh
wat2wasm target/build/main/main.wat -o moonbit.wasm
```

或者你也可以直接使用当前文件夹中的`moonbit.wasm`。

使用`python3 -m http.server 8080`启动一个 Web 服务器，现在我们可以通过访问http://127.0.0.1:8080/ 来测试 Moonbit 的基准性能。

<img width="600" src="imgs/moonbit_bench.png">

### Go 语言

**注意：请勿使用当前文件夹中的`wasm_exec.js`。** 从你的`GOROOT`中复制一份：

```sh
cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" $PWD
```

构建`golang.wasm`：

```sh
GOOS=js GOARCH=wasm go build -o golang.wasm./main.go
```

使用`python3 -m http.server 8080`启动一个 Web 服务器，现在我们可以通过访问http://127.0.0.1:8080/ 来测试 Go 语言的基准性能。

<img width="600" src="imgs/golang_bench.png">

### Rust 语言

```sh
rustup target add wasm32-unknown-unknown
cd fib-rust
cargo build --target wasm32-unknown-unknown --release
mv target/wasm32-unknown-unknown/release/fib-rust.wasm../rust.wasm
```

<img width="600" src="imgs/rust_bench.png">
