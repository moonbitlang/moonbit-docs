# MoonBit

MoonBit 是一个用于云计算和边缘计算的 WebAssembly 端到端编程语言工具链。
您可以在 https://try.moonbitlang.cn 获得 IDE 环境，无需安装任何软件，也不依赖任何服务器。

## 状态

MoonBit 目前处于 Pre-alpha 阶段，是实验性质的。我们期望明年达到 beta 阶段。

## 主要优势

- 生成与现有解决方案相比显著更小的 WASM 文件。
- 更高的运行时性能。
- 先进的编译时性能。
- 简单但实用的数据导向语言设计。

## 概述

一个月兔程序由类型定义，函数定义和变量绑定组成。
每个包的入口点是一个特殊的 `init` 函数。`init` 函数特殊在以下两个方面：

1. 在同一个包中可以有多个 `init` 函数。
1. `init` 函数不能被显式地调用或被其他函数引用。相反，在一个包初始化时，所有的 `init` 函数都将被隐式地调用。因此，`init` 函数只应该包含语句。

```rust live
fn init {
  print("Hello world!") // OK
}

fn init {
  let x = 1
  // x // fail
  print(x) // success
}
```

MoonBit 区分语句和表达式。在一个函数体中，只有最后一句应该是作为返回值的表达式。例如：

```rust live
fn foo() -> Int {
  let x = 1
  x + 1 // OK
}

fn bar() -> Int {
  let x = 1
  x + 1 // fail
  x + 2
}

fn init {
  print(foo())
  print(bar())
}
```

### 表达式和语句

表达式包括：

- 值字面量（例如布尔值、数字、字符、字符串、数组、元组、结构体）
- 算术、逻辑或比较操作
- 访问数组元素（例如 `a[0]`）或结构体字段（例如 `r.x`）或元组组成部分（例如 `t.0`）
- 变量和（大写字母开头的）枚举构造器
- 匿名局部函数定义
- `match` 和 `if`表达式

语句包括：

- 命名局部函数定义
- 局部变量绑定
- 赋值
- While 循环和相关的控制流结构（`break` 和 `continue`）
- `return` 语句
- 返回类型为 `unit` 的任何表达式

## 函数

函数接受参数并产生结果。
在 MoonBit 中，函数是一等公民，这意味着函数可以作为其他函数的参数或返回值。

### 顶层函数

函数可以被定义为顶层或局部。
我们可以使用 `fn` 关键字定义一个顶层函数，
例如以下求三个整数之和并返回结果的函数：

```rust
fn add3(x: Int, y: Int, z: Int)-> Int {
  x + y + z
}
```

注意顶层函数的参数和返回值类型需要显式标注。如果返回类型被省略，函数将被视为返回 `unit` 类型。

### 局部函数

局部函数使用 `fn` 关键字定义。局部函数可以是命名或匿名的。在大多数情况下，局部函数的类型注解可以省略，因为编译器可以自动推断。例如：

```rust live
fn foo() -> Int {
  fn inc(x) { x + 1 }  // named as `inc`
  fn (x) { x + inc(2) } (6) // anonymous, instantly applied to integer literal 6
}

fn init {
  print(foo())
}
```

无论是命名的还是匿名的，函数都是 _词法闭包_：任何没有局部绑定的标识符必须引用来自周围词法范围的绑定

```rust live
let y = 3
fn foo(x: Int) {
  fn inc()  { x + 1 } // OK, will return x + 1
  fn four() { y + 1 } // Ok, will return 4
  print(inc())
  print(four())
}

fn init {
  foo(2)
}
```

### 函数调用

函数可以用圆括号内的参数列表进行调用：

```rust
add3(1, 2, 7)
```

这适用于命名函数（如前面的例子）和绑定到函数值的变量，如下所示：

```rust live
fn init {
  let add3 = fn(x, y, z) { x + y + z }
  print(add3(1, 2, 7))
}
```

表达式 `add3(1, 2, 7)` 返回 `10`。任何求值为函数值的表达式都可以被调用：

```rust live
fn init {
  let f = fn (x) { x + 1 }
  let g = fn (x) { x + 2 }
  print((if true { f } else { g })(3)) // OK
}
```

## 控制结构

### 条件表达式

条件表达式由条件、结果和一个可选的 `else` 子句组成。

```rust
if x == y {
  expr1
} else {
  expr2
}

if x == y {
  expr1
}
```

`else` 子句也可以包含另一个 `if-else` 表达式：

```rust
if x == y {
  expr1
} else if z == k {
  expr2
}
```

花括号在结果或 `else` 子句中用于组合表达式

需要注意的是，在 MoonBit 中，条件表达式总是返回一个值，结果和 `else` 子句的返回值类型必须相同。

### 函数式循环

函数式循环是 MoonBit 中的一个强大特性，它允许您以函数式风格编写循环。

函数式循环接受参数并返回一个值。它使用 loop 关键字定义，后跟其参数和循环体。循环体是一系列子句，每个子句由模式和表达式组成。与输入匹配的模式将被执行，并且循环将返回表达式的值。如果没有匹配的模式，循环将抛出异常。使用 continue 关键字和参数来开始下一次循环迭代。使用 break 关键字和参数来从循环中返回一个值。如果值是循环体中的最后一个表达式，则可以省略 break 关键字。

```rust
fn sum(xs: List[Int]) -> Int {
  loop xs, 0 {
    Nil, acc => break acc // break can be omitted
    Cons(x, rest), acc => continue rest, x + acc
  }
}

fn init {
  println(sum(Cons(1, Cons(2, Cons(3, Nil)))))
}
```

### 循环

MoonBit 的 `while` 循环可以用如下语法定义：

```rust
while x == y {
  expr1
}
```

`while` 语句不返回任何值；它只求值成 `unit` 类型的 `()`
MoonBit 还提供 `break` 和 `continue` 语句来控制循环流。

```rust
let mut i = 0
let mut n = 0

while i < 10 {
  i = i + 1
  if (i == 3) {
    continue
  }

  if (i == 8) {
    break
  }
  n = n + i
}
// n = 1 + 2 + 4 + 5 + 6 + 7
println(n) // outputs 25
```

`while` 循环还可以有一个可选的 "continue" 块。"continue" 块位于循环条件和循环体之间，和循环条件用逗号分隔。它会在每次循环的循环体之后、下一次循环的循环条件之前被执行：

```rust
let mut i = 0
while i < 10, i = i + 1 {
  println(i)
} // outputs 0 to 9
```

如果在一个 "continue" 块里有多个语句，它们需要被花括号包裹。循环体中的 `continue` 语句不会跳过 "continue" 块。例如，下面的例子会输出小于 10 的所有奇数：

```rust
let mut i = 1
while i < 10, i = i + 1 {
  if (i % 2 == 0) {
    continue
  }
  println(i)
} // outputs 1 3 5 7 9
```

## 内置数据结构

### 布尔值

MoonBit 内置了布尔类型，它有两个值：`true` 和 `false`。布尔类型用于条件表达式和控制结构。

```rust
let a = true
let b = false
let c = a && b
let d = a || b
let e = not(a)
```

### 数字

Moonbit 支持数字的字面量，包括十进制，二进制，八进制和十六进制数。

为了提升可读性，你可以在数字字面量中间插入下划线，例如 `1_000_000`。注意到下划线可以被插入在数字之间的任何位置，不只是每三个数字。

- 十进制数没有任何出人意料的地方。

```rust
let a = 1234
let b = 1_000_000 + a
let large_num = 9_223_372_036_854_775_807L // Int64 类型的整数必须有'L'作为后缀
```

- 一个八进制数有一个前缀 0 接着一个字母 O，也就是 `0o` 或 `0O`。注意到在 `0o` 或 `0O` 之后出现的数字只能在 `0` 到 `7` 之间。

```rust
let octal = 0o1234
let another_octal = 0O1234
```

- 一个十六进制数有一个前缀 0 接着一个字母 X，也就是 `0x` 或 `0X`。注意到在 `0x` 或 `0X` 之后出现的数字只能是 `0123456789ABCDEF` 之一。

```rust
let hex = 0XA
let another_hex = 0xA
```

### 字符串

字符串插值是 MoonBit 中的一个强大功能，它允许在插值字符串中替换变量。该功能通过直接将变量值嵌入文本中来简化构建动态字符串的过程

```rust live
fn init {
  let x = 42
  print("The answer is \(x)")
}
```

用于字符串插值的变量必须支持 `to_string` 方法。

### 元组

元组是一个有限值的集合，使用圆括号 `()` 构造，其中元素由逗号 `,` 分隔。
元素的顺序很重要，例如 `(1, true)` 和 `(true, 1)` 是不同的类型。以下是一个例子：

```rust live
fn pack(a: Bool, b: Int, c: String, d: Double) -> (Bool, Int, String, Double) {
    (a, b, c, d)
}
fn init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
}
```

可以通过模式匹配或索引来访问元组：

```rust live
fn f(t : (Int, Int)) {
  let (x1, y1) = t // access via pattern matching
  // access via index
  let x2 = t.0
  let y2 = t.1
  if (x1 == x2 && y1 == y2) {
    print("yes")
  } else {
    print("no")
  }
}

fn init {
  f((1, 2))
}
```

### 数组

数组是由方括号 `[]` 构造的有限值序列，其中元素由逗号 `,` 分隔。例如：

```rust
let array = [1, 2, 3, 4]
```

可以使用 `array[x]` 来引用第 x 个元素。索引从零开始。

```rust live
fn init {
  let array = [1, 2, 3, 4]
  let a = array[2]
  array[3] = 5
  let b = a + array[3]
  print(b) // prints 8
}
```

## 变量绑定

变量可以通过 `let mut` 或 `let` 分别声明为可变或不可变。
可变变量可以重新赋值，不可变变量则不能。

```rust live
let zero = 0

fn init {
  let mut i = 10
  i = 20  
  print(i + zero)
}
```

## 数据类型

创建新数据类型的方法有两种：`struct` 和 `enum`。

### 结构

在 MoonBit 中，结构与元组类似，但是它们的字段由字段名索引。
结构体可以使用结构体字面量构造，结构体字面量由一组带有标签的值组成，并用花括号括起来。
如果结构体字面量的字段完全匹配类型定义，则其类型可以被自动推断。
使用点语法 `s.f` 可以访问结构体字段。
如果一个字段使用关键字 `mut` 标记为可变，那么可以给它赋予新的值。

```rust live
struct User {
  id: Int
  name: String
  mut email: String
}

fn init {
  let u = { id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  print(u.id)
  print(u.name)
  print(u.email)
}
```

注意，您还可以在结构类型中包含与之关联的方法，例如：

```rust
struct Stack {
  mut elems: List[Int]
  push: (Int) -> Unit
  pop: () -> Int
}
```

### 枚举

枚举类型和函数式语言中的代数数据类型类似。
枚举可以有一组情况，并且每个情况和元组类似，可以指定不同类型的关联值。
每个情况的标签必须大写，称为数据构造函数。
可以通过调用带有指定类型参数的数据构造函数来构造枚举。
枚举的构造必须使用标明类型。
可以通过模式匹配来解构枚举，并且可以将关联值绑定到每个模式中指定的变量。

```rust live
enum List {
  Nil
  Cons (Int, List)
}

fn print_list(l: List) {
  match l {
    Nil => print("nil")
    Cons(x, xs) => {
      print(x)
      print(",")
      print_list(xs)
    }
  }
}

fn init {
  let l: List = Cons(1, Cons(2, Nil))
  print_list(l)
}
```

### Newtype

MoonBit 支持一种特殊的枚举类型，称为 newtype，用于从现有类型创建新类型。一个 newtype 只能有一个情况，并且该情况只能有一个关联值。

```rust
type UserId Int
type UserName String
```

Newtype的名称既是类型又是数据构造函数。新类型的构造和解构遵循与枚举相同的规则。

```rust
fn init {
  let id: UserId = UserId(1)
  let name: UserName = UserName("John Doe")
  let UserId(uid) = id
  let UserName(uname) = name
  println(uid)
  println(uname)
}
```

也可以使用 `.0` 对 Newtype 进行解构：

```rust
fn init {
  let id: UserId = UserId(1)
  let uid = id.0
  println(uid)
}
```

## 模式匹配

我们已经展示了对枚举进行模式匹配的用例，但是模式匹配不局限于枚举。
例如，我们也可以对布尔值、数字、字符、字符串、元组、数组和结构体字面量进行模式匹配。
由于这些类型和枚举不同，它们只有一种情况，因此我们可以直接使用 `let` 绑定来对它们进行模式匹配。
需要注意的是，在 `match` 中绑定的变量的作用域仅限于引入该变量的分支，而 `let` 绑定将引入每个变量到当前作用域。
此外，我们可以使用下划线 `_` 作为我们不关心的值的通配符。

```rust
let id = match u {
  { id: id, name: _, email: _ } => id
}
// is equivalent to
let { id: id, name: _, email: _ } = u
```

在模式匹配中还有一些其他有用的构造。
例如，我们可以使用 `as` 为某个模式指定一个名称，并且可以使用 `|` 同时匹配多个情况。

```rust
match expr {
  e as Lit(n) => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  _ => ...
}
```

## 泛型

您可以在顶层的函数和数据结构定义中使用泛型。
类型参数可以由方括号引入。
我们可以重写前面提到的数据类型 `List`，添加类型参数 `T`，以获得一个泛型版本的列表。
然后，我们可以定义泛型函数 `map` 和 `reduce`，用于对列表进行操作。

```rust
enum List[T] {
  Nil
  Cons(T, List[T])
}

fn map[S, T](self: List[S], f: (S) => T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

fn reduce[S, T](self: List[S], op: (T, S) => T, init: T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}
```

## 访问控制

默认情况下，所有函数定义和变量绑定对其他包是 _不可见_ 的；
没有修饰符的类型是抽象数据类型，其名称被导出，但内部是不可见的。
这种设计防止了意外暴露实现细节。
您可以在 `type`/`fn`/`let` 前使用 `pub` 修饰符使其完全可见，或在 `type` 前使用 `priv` 修饰符使其对其他包完全不可见。
您还可以在字段名前使用 `pub` 或 `priv` 获得更细粒度的访问控制。
但是，请注意：

- 在抽象或私有结构体内，所有字段都不能被定义为 `pub`，因为这样没有意义。
- 枚举类型的构造器没有单独的可见性，所以不能在它们前面使用 `pub` 或 `priv`

```rust
struct R1 {       // abstract data type by default
  x: Int          // implicitly private field
  pub y: Int      // ERROR: `pub` field found in a abstract type!
  priv z: Int     // WARNING: `priv` is redundant!
}

pub struct R2 {       // explicitly public struct
  x: Int              // implicitly public field
  pub y: Int          // WARNING: `pub` is redundant!
  priv z: Int         // explicitly private field
}

priv struct R3 {       // explicitly private struct
  x: Int               // implicitly private field
  pub y: Int           // ERROR: `pub` field found in a private type!
  priv z: Int          // WARNING: `priv` is redundant!
}

enum T1 {       // abstract data type by default
  A(Int)        // implicitly private variant
  pub B(Int)    // ERROR: no individual visibility!
  priv C(Int)   // ERROR: no individual visibility!
}

pub enum T2 {       // explicitly public enum
  A(Int)            // implicitly public variant
  pub B(Int)        // ERROR: no individual visibility!
  priv C(Int)       // ERROR: no individual visibility!
}

priv enum T3 {       // explicitly private enum
  A(Int)             // implicitly private variant
  pub B(Int)         // ERROR: no individual visibility!
  priv C(Int)        // ERROR: no individual visibility!
}
```

MoonBit 中另一个有用的特性是 `pub(readonly)` 类型，其受到了 OCaml [private types](https://v2.ocaml.org/manual/privatetypes.html)的启发。简而言之，`pub(readonly)` 类型的值可以使用模式匹配或点语法析构，但在其他包中，不能被构造或改变。注意到在 `pub(readonly)` 类型定义的同一个包中，它没有任何限制。

```rust
// Package A
pub(readonly) struct RO {
  field: Int
}
fn init {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
fn print_RO(r : RO) {
  print("{ field: ")
  print(r.field)  // OK
  print(" }")
}
fn init {
  let r : RO = { field: 4 }  // ERROR: Cannot create values of the public read-only type RO!
  let r = { ..r, field: 8 }  // ERROR: Cannot mutate a public read-only field!
}
```

MoonBit 中的访问控制遵循这样一个原则：`pub` 类型、函数或变量不能基于私有类型进行定义。
这是因为私有类型可能不是在使用 `pub` 实体的所有地方都可以被访问。
MoonBit 内建了一些检查，以防止违反这一原则的用例。

```rust
pub struct s {
  x: T1  // OK
  y: T2  // OK
  z: T3  // ERROR: public field has private type `T3`!
}

// ERROR: public function has private parameter type `T3`!
pub fn f1(_x: T3) -> T1 { T1::A(0) }
// ERROR: public function has private return type `T3`!
pub fn f2(_x: T1) -> T3 { T3::A(0) }
// OK
pub fn f3(_x: T1) -> T1 { T1::A(0) }

pub let a: T3  // ERROR: public variable has private type `T3`!
```

## 方法系统

MoonBit 支持与传统面向对象语言不同的方法(method)。
某个类型的一个方法就是一个与该类型关联的普通函数。
可以使用 `fn TypeName::method_name(...) -> ...` 的语法来为类型 `TypeName` 声明方法：

```rust
enum MyList[X] {
  Nil,
  Cons(X, MyList[X])
}

fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> MyList[Y] { ... }
fn MyList::concat[X](xs: MyList[MyList[X]]) -> MyList[X] { ... }
```

如果一个函数的第一个参数名为 `self`，那么 MoonBit 会自动将这个函数定义为 `self` 的类型上的方法：

```rust
fn map[X, Y](self: MyList[X], f: (X) -> Y) -> List[Y] { ... }
// 等价于
fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> List[Y] { ... }
```

方法就是由某个类型所有的普通函数。所以，在没有歧义时，它们也可以像普通函数一样调用：

```rust
fn init {
  let xs: MyList[MyList[_]] = ...
  let ys = concat(xs)
}
```

但和普通函数不同，方法支持重载。不同的类型可以有同名的方法。如果当前作用域内有多个同名方法，依然可以通过加上 `TypeName::` 的前缀来显式地调用一个方法：

```rust
struct T1 { x1: Int }
fn T1::default() -> { { x1: 0 } }

struct T2 { x2: Int }
fn T2::default() -> { { x2: 0 } }

fn init {
  // default() 有歧义！
  let t1 = T1::default() // 可行
  let t2 = T2::default() // 可行
}
```

## 运算符重载

MoonBit 支持通过方法重载内置运算符。与运算符 `<op>` 相对应的方法名称是 `op_<op>`。例如：

```rust live
struct T {
  x:Int
} derive(Debug)

fn op_add(self: T, other: T) -> T {
  { x: self.x + other.x }
}

fn init {
  let a = { x:0, }
  let b = { x:2, }
  debug(a + b)
}
```

目前，以下运算符可以被重载：

| operator name        | method name |
| -------------------- | ----------- |
| `+`                  | `op_add`    |
| `-`                  | `op_sub`    |
| `*`                  | `op_mul`    |
| `/`                  | `op_div`    |
| `%`                  | `op_mod`    |
| `-`(unary)           | `op_neg`    |
| `_[_]`(get item)     | `op_get`    |
| `_[_] = _`(set item) | `op_set`    |


## 管道运算符
MoonBit 提供一个便利的管道运算符 `|>`，可以用于链式调用普通函数：

```rust
fn init {
  x |> f // 相当于 f(x)
  x |> f(y) // 相当于 f(x, y)
  initial
  |> function1
  |> function2(other_arguments)
}
```

## 接口系统

MoonBit 具有用于重载/特设多态的结构接口系统。接口可以声明如下：

```rust
trait I {
  f(Self, ...) -> ...
}
```

接口无需显式实现，具有所需方法的类型会自动实现接口。例如，以下接口：

```rust
trait Show {
  to_string(Self) -> String
}
```

内置类型如 `Int` 和 `Double` 会自动实现这个接口。

在声明泛型函数时，类型参数可以用它们应该实现的接口进行注解。如此便能定义只对某些类型可用的泛型函数。例如：

```rust
trait Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

fn square[N: Number](x: N) -> N {
  x * x
}
```

如果没有 `Number` 的要求，`square` 中的表达式 `x * x` 会导致找不到方法/运算符的错误。
现在，函数 `square` 可以与任何实现了 `Number` 接口的类型一起使用，例如：

```rust live
fn init {
  debug(square(2)) // 4
  debug(square(1.5)) // 2.25
  debug(square({ x: 2, y: 3 })) // (4, 9)
}

struct Point {
  x: Int
  y: Int
} derive(Debug)

fn op_add(self: Point, other: Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

fn op_mul(self: Point, other: Point) -> Point {
  { x: self.x * other.x, y: self.y * other.y }
}
```

接口中的方法可以用 `Trait::method` 的语法来直接调用。MoonBit 会推导 `Self` 的具体类型，并检查 `Self` 是否实现了 `Trait`：

```rust
fn init {
  println(Show::to_string(42))
  debug(Compare::compare(1.0, 2.5))
}
```

Moonbit 提供下列实用的内建接口：

```rust
trait Eq {
  op_equal(Self, Self) -> Bool
}

trait Compare {
  // `0` 代表相等, `-1` 代表小于, `1` 代表大于
  op_equal(Self, Self) -> Int
}

trait Hash {
  hash(Self) -> Int
}

trait Show {
  to_string(Self) -> String
}

trait Default {
  default() -> Self
}

trait Debug {
  // 将 [self] 的调试信息写入到一个 buffer 里
  debug_write(Self, Buffer)
}
```

## 方法的访问权限控制与拓展方法
为了使 MoonBit 的接口系统具有一致性（coherence，即任何 `Type: Trait` 的组合都有全局唯一的实现），
防止第三方包意外地修改现有程序的行为，**只有类型所在的包能为它定义方法**。
所以用户无法为内建类型或来自第三方包的类型定义方法。

然而，有时候也会出现拓展一个现有类型的功能的需求。
因此，MoonBit 提供了一种名为拓展方法的机制。拓展方法可以通过 `fn Trait::method_name(...) -> ...` 的形式声明，
它们通过实现一个接口的方式拓展现有类型的功能。
例如，假如要为内建类型实现一个新的接口 `ToMyBinaryProtocol`，就可以（且必须）使用拓展方法：

```rust
trait ToMyBinaryProtocol {
  to_my_binary_protocol(Self, Buffer)
}

fn ToMyBinaryProtocol::to_my_binary_protocol(x: Int, b: Buffer) { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: Double, b: Buffer) { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: String, b: Buffer) { ... }
```

在搜索某个接口的实现时，拓展方法比普通方法有更高的优先级。所以拓展方法还可以用来覆盖掉行为不能满足要求的现有方法。
拓展方法只能被用于实现指定的接口，不能像普通的方法一样被直接调用。
此外，**只有类型或接口所在的包可以定义拓展方法**。
例如，只有 `@pkg1` 和 `@pkg2` 能为类型 `@pkg2.Type` 定义拓展方法 `@pkg1.Trait::f`。
这一限制使得 MoonBit 的接口系统在加入拓展方法这一灵活的机制后，依然是一致的。

如果需要直接调用一个拓展方法，可以使用 `Trait::method` 语法。例如：

```rust
trait MyTrait {
  f(Self)
}

fn MyTrait::f(self: Int) {
  println("Got Int \(self)!")
}

fn init {
  MyTrait::f(42)
}
```

## 自动实现内建接口

Moonbit 可以自动生成一些内建接口的实现:

```rust
struct T {
  x: Int
  y: Int
} derive(Eq, Compare, Debug, Default)

fn init {
  let t1 = T::default()
  let t2 = { x: 1, y: 1 }
  debug(t1) // {x: 0, y: 0}
  debug(t2) // {x: 1, y: 1}
  debug(t1 == t2) // false
  debug(t1 < t2) // true
}
```

## 接口对象
MoonBit 通过接口对象的形式支持运行时的多态。
假设  `t` 的类型为 `T`，而且类型 `T` 实现了接口 `I`,
那么可以把 `T` 实现 `I` 的各个方法和 `t` 自己打包在一起，
创建一个 `I` 的接口对象 `t as I`。
接口对象擦除了值的具体类型，所以从不同的具体类型创建的接口对象可以被装在同一个数据结构里、统一地进行处理：

```rust
trait Animal {
  speak(Self)
}

type Duck String
fn Duck::make(name: String) -> Duck { Duck(name) }
fn speak(self: Duck) {
  println(self.0 + ": quak!")
}

type Fox String
fn Fox::make(name: String) -> Fox { Fox(name) }
fn Fox::speak(_self: Fox) {
  println("What does the fox say?")
}

fn init {
  let duck1 = Duck::make("duck1")
  let duck2 = Duck::make("duck2")
  let fox1 = Fox::make("fox1")
  let animals = [ duck1 as Animal, duck2 as Animal, fox1 as Animal ]
  let mut i = 0
  while i < animals.length(), i = i + 1 {
    animals[i].speak()
  }
}
```

不是所有接口都可以用于创建对象。
“对象安全” 的接口的方法必须满足下列条件：

- 方法的第一个参数必须是 `Self`
- 在方法的签名里，`Self` 只能出现在第一个参数

## 问号操作符
MoonBit 提供一个便捷的 `?` 操作符，用于错误处理。
`?` 是一个后缀运算符。它可以作用于类型为 `Option` 或 `Result` 的表达式。
被应用在表达式 `t : Option[T]` 上时，`t?` 等价于：

```rust
match t {
  None => { return None }
  Some(x) => x
}
```

被应用在表达式 `t : Result[T, E]` 上时，`t?` 等价于：

```rust
match t {
  Err(err) => { return Err(err) }
  Ok(x) => x
}
```

问号操作符可以用于优雅地组合多段可能失败或产生错误的程序：

```rust
fn may_fail() -> Option[Int] { ... }

fn f() -> Option[Int] {
  let x = may_fail()?
  let y = may_fail()?.lsr(1) + 1
  if y == 0 { return None }
  Some(x / y)
}

fn may_error() -> Result[Int, String] { ... }

fn g() -> Result[Int, String] {
  let x = may_error()?
  let y = may_error()? * 2
  if y == 0 { return Err("divide by zero") }
  Ok(x / y)
}
```

## MoonBit 的构建系统

构建系统的介绍可以在 [MoonBit 的构建系统教程](./build-system-tutorial.md) 中找到。
