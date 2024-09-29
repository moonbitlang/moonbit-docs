# MoonBit 错误处理

错误处理在我们 MoonBit 的语言设计中一直占据中心地位。在下面的文章中我们将介绍如何使用错误处理功能。
我们假定您有一定 MoonBit 的先验知识，若还没有，请参阅 [MoonBit 新手之旅](./tour.md)。

## 实例：除数为零

我们先来写一个简单的例子来引入最基本的错误处理写法。
考虑下面的 `div` 函数，当除数为 0 时会抛出对应错误：

```moonbit
type! DivisionByZeroError String
fn div(x : Int, y : Int) -> Int!DivisionByZeroError {
  if y == 0 {
    raise DivisionByZeroError("division by zero")
  }
  x / y
}
```

之前我们通常用 `type` 关键字来定义一个已有外部类型的包装类型；但在这里，我们在 `type` 后加一个 `!`
来定义一个错误类型 `DivisionByZeroError`，其内部是 `String`。

> `type! E S` 可以从 `S` 构造一个错误类型 `E`

和 `type` 一样，`type!` 也可以附带一些数据（Payload），例如上面的 `DivisionByZeroError`；也可以不带，
还可以像 `enum` 一样拥有多个构造子：

```moonbit
type! ConnectionError {
  BrokenPipe(Int,String)
  ConnectionReset
  ConnectionAbort
  ConnectionRefused
}
```

错误类型最基本的使用方法就是定义一个能抛出对应错误的函数。一个可报错的函数具有形如 `T ! E` 的返回类型，
其中 `T` 是实际的数据类型，而 `E` 则是错误类型。在这个例子中，它们是 `Int!DivisionByZeroError`。
在函数体内可以通过 `raise e` 来抛出错误，其中 `e` 为 `E` 的错误实例，可以用 `E` 的默认构造子 `S` 构造出来。

在 MoonBit 中任何错误实例都是二等公民，即它只能作为返回值。
如果返回值确实包含一个错误实例，那么也应该修改函数签名以保证类型一致。

实际上，自带的 `test` 测试块亦可被看作是一个函数，且这个函数的返回类型是 `Unit!Error`。

## 调用可报错的函数

可报错的函数有两种调用形式：`f!(...)` 和 `f?(...)`。

### 直接调用

`f!(...)` 直接调用函数，因而可能出现的错误必须在调用 `f` 的函数中处理。我们可以重新抛出错误而不处理之：

```moonbit -e1001 -e1002
//需要保证 `div2` 和 `div` 的错误类型一致
fn div2(x : Int, y : Int) -> Int!DivisionByZeroError {
  div!(x,y)
}
```

或是和许多语言一样使用 `try...catch` 来捕捉错误：

```moonbit
fn div3(x : Int, y : Int) -> Unit {
  try {
    div!(x, y)
  } catch { // 也可以使用等价的 `except` 关键字
    DivisionByZeroError(e) => println("inf: \{e}")
  } else {
    v => println(v)
  }
}
```

`catch...` 句式具有和模式匹配类似的语义，我们可以脱去外层的错误类型，提取出内部类 `String` 并输出它。
除此之外，还能使用 `else` 从句来处理 `try...` 部分的值。

```moonbit
fn test_try() -> Result[Int, Error] {
  // 编译器可以推断出本地报错函数的类型
  fn f() -> _!_ {
    raise Failure("err")
  }

  try Ok(f!()) { err => Err(err) }
}
```

如果 `try` 部分的代码仅仅是一个表达式，那么还可以省略 `catch` 关键字。如果某个 `try` 中可能抛出多种错误，
可以用特殊的 `catch!` 来捕捉其中的一部分错误，对于未捕捉的错误直接重新抛出：

```moonbit
type! E1
type! E2
fn f1() -> Unit!E1 { raise E1 }
fn f2() -> Unit!E2 { raise E2 }
fn f() -> Unit! {
  try {
    f1!()
    f2!()
  } catch! {
    E1 => println("E1")
    // 重新抛出 E2
  }
}
```

### 转换为 Result

#### 提取数据

类型为 `Result` 的对象在 MoonBit 中是头等公民。`Result` 有两个构造子：`Ok(...)` 和 `Err(...)`，
其中前者接收一个头等对象，后者接收一个错误对象。

使用 `f?(...)` 可将返回类型 `T!E` 转换成 `Result[T,E]`。我们可以使用模式匹配来提取其中的值：

```moonbit enclose
let res = div?(10, 0)
match res {
  Ok(x) => println(x)
  Err(DivisionByZeroError(e)) => println(e)
}
```

`f?()` 其实是以下代码的语法糖：

```moonbit enclose
let res = try {
  Ok(div!(10, 0))
} catch {
  s => Err(s)
}
```

> 注意 `T?` 和 `f?(...)` 的差别： `T` 是一个类型且 `T?` 等价于 `Option[T]`；
> `f?(...)` 则是调用某个可报错的函数 `f`。

除了模式匹配之外，`Result` 本身还带了一些有用的方法来处理可能出现的错误：

```moonbit no-check
let res1: Result[Int, String] = Err("error")
let value = res1.or(0) // 0

let res2: Result[Int, String] = Ok(42)
let value = res2.unwrap() // 42
```

- `or`：当结果为 `Ok` 时返回值，错误时返回默认值
- `unwrap`：当结果为 `Ok` 时返回值，错误时 panic

#### 映射值

```moonbit no-check
let res1: Result[Int, String] = Ok(42)
let new_result = res1.map(fn(x) { x + 1 }) // Ok(43)

let res2: Result[Int, String] = Err("error")
let new_result = res2.map_err(fn(x) { x + "!" }) // Err("error!")
```

- `map` 当结果为 `Ok` 时将函数应用于内部的值，否则不做任何事
- `map_error` 则是反过来

和一些语言不同，MoonBit 将可报错和可空的值当成两种不同的对象来处理，但我们通常以相同的方式处理它们：一个结果为 `Err` 的值不含任何实际值，只有错误本身，这和空值（null）比较像，而 MoonBit 知道这一点。

- `to_option` 将一个 `Result` 转换为 `Option`

```moonbit no-check
let res1: Result[Int, String] = Ok(42)
let option = res1.to_option() // Some(42)

let res2: Result[Int, String] = Err("error")
let option1 = res2.to_option() // None
```

## 内置错误类型和相关函数

在 MoonBit 中，`Error` 用于指代所有的错误类型：

```moonbit no-check
// 这些函数的签名等价，都抛出 Error
fn f() -> Unit! { .. }
fn f!() -> Unit { .. }
fn f() -> Unit!Error { .. }

fn test_error() -> Result[Int, Error] {
  fn f() -> _!_ {
    raise DivisionByZeroError("err")
  }

  try {
    Ok(f!())
  } catch {
    err => Err(err)
  }
}
```

虽然构造子 `Err` 期待接收一个 `Error` 类型的对象，但我们仍能够传给它一个 `DivisionByZeroError`。

但 `Error` 类型的对象不能直接构造出来，它仅被用于传递，并非直接使用：

```moonbit
type! ArithmeticError

fn what_error_is_this(e : Error) -> Unit {
  match e {
    DivisionByZeroError(_) => println("DivisionByZeroError")
    ArithmeticError => println("ArithmeticError")
    ... => println("...")
    _ => println("Error")
  }
}
```

`Error` 适合不需要具体错误类型的场景，也可以单纯把它用作能够匹配所有子错误类型的泛型。

上面的代码中，因为 `Error` 包含了多个错误类型，部分匹配是不允许的，
所以我们必须要提供一个通配符 `_` 或者 `Error` 作为兜底的规则来匹配剩下的错误类型。

我们通常用内置的 `Failure` 错误类型来表示宽泛的错误，在这里宽泛一词表示各种琐碎的，
不值得单独定义一个错误类型的错误。

```moonbit
fn div_trivial(x : Int, y : Int) -> Int!Failure {
  if y == 0 {
    raise Failure("division by zero")
  }
  x / y
}
```

除了直接用构造子构造 `Failure`，还可以用函数 `fail!`，后者更快捷。`fail!` 的内部实现是

```moonbit
pub fn fail[T](msg : String, ~loc : SourceLoc = _) -> T!Failure {
  raise Failure("FAILED: \{loc} \{msg}")
}
```

可以看出，在作用上其不过是有错误信息模板的构造子，可以输出错误信息和错误对应的文件位置。
实际使用中，`fail!` 比 `Failure` 更常用。

其他可以破坏控制流的函数包括 `abort` 和 `panic`。这两者是等价的。
任一位置的 `panic` 都能在该位置将程序崩溃并输出对应 stack trace。
