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
每个包的入口点是一个特殊的`init`函数。`init`函数特殊在以下两个方面：

1. 在同一个包中可以有多个 `init` 函数。
1. `init` 函数不能被显式地调用或被其他函数引用。相反，在一个包初始化时，所有的`init`函数都将被影式地调用。因此，`init`函数只应该包含语句。

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
- 访问数组元素（例如`a[0]`）或结构体字段（例如`r.x`）或元组组成部分（例如`t.0`）
- 变量和（大写字母开头的）枚举构造器
- 匿名局部函数定义
- `match`和`if`表达式

语句包括：

- 命名局部函数定义
- 局部变量绑定
- 赋值
- While 循环和相关的控制流结构（`break`和`continue`）
- `return`语句
- 返回类型为`unit`的任何表达式

## 函数

函数接受参数并产生结果。
在 MoonBit 中，函数是一等公民，这意味着函数可以作为其他函数的参数或返回值。

### 顶层函数

Functions can be defined as top-level or local.
函数可以被定义为顶层或局部。
我们可以使用`fn`关键字定义一个顶层函数，
例如以下求三个整数之和并返回结果的函数：

```rust
fn add3(x: Int, y: Int, z: Int)-> Int {
  x + y + z
}
```

注意顶层函数的参数和返回值类型需要显式标注。如果返回类型被省略，函数将被视为返回`unit`类型。

### 局部函数

局部函数使用`fn`关键字定义。局部函数可以是命名或匿名的。在大多数情况下，局部函数的类型注解可以省略，因为编译器可以自动推断。例如：

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

表达式`add3(1, 2, 7)`返回`10`。任何求值为函数值的表达式都可以被调用：

```rust live
fn init {
  let f = fn (x) { x + 1 }
  let g = fn (x) { x + 2 }
  print((if true { f } else { g })(3)) // OK
}
```

## 控制结构

### 条件表达式

条件表达式由条件、结果和一个可选的`else`子句组成。

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

`else`子句也可以包含另一个`if-else`表达式：

```rust
if x == y {
  expr1
} else if z == k {
  expr2
}
```

花括号在结果或 `else` 子句中用于组合表达式

需要注意的是，在 MoonBit 中，条件表达式总是返回一个值，结果和`else`子句的返回值类型必须相同。

### 循环

MoonBit 中的主要循环语句是 while 循环：

```rust
while x == y {
  expr1
}
```

while 语句不返回任何值；它只求值成`unit`类型的`()`
MoonBit 还提供`break`和`continue`语句来控制循环流。

## 内置数据结构

### 数字

Moonbit 支持数字的字面量，包括十进制，二进制，八进制和十六进制数。

为了提升可读性，你可以在数字字面量中间插入下划线，例如 `1_000_000`。注意到下划线可以被插入在数字之间的任何位置，不只是每三个数字。

- 十进制数没有任何出人意料的地方。

```
let a = 1234
let b = 1_000_000 + a
let large_num = 9_223_372_036_854_775_807L // Int64 类型的整数必须有'L'作为后缀
```

- 一个八进制数有一个前缀 0 接着一个字母 O，也就是 `0o` 或 `0O`。注意到在 `0o` 或 `0O` 之后出现的数字只能在 `0` 到 `7` 之间。

```
let octal = 0o1234
let another_octal = 0O1234
```

- 一个十六进制数有一个前缀 0 接着一个字母 X，也就是 `0x` 或 `0X`。注意到在 `0x` 或 `0X` 之后出现的数字只能是 `0123456789ABCDEF` 之一。

```
let hex = 0XA
let another_hex = 0xA
```

### 字符串

字符串插值是 MoonBit 中的一个强大功能，它允许在插值字符串中替换变量。该功能通过直接将变量值嵌入文本中来简化构建动态字符串的过程

```rust live
fn init {
  x := 42
  print("The answer is \(x)")
}
```

用于字符串插值的变量必须支持 `to_string` 方法。

### 元组

元组是一个有限值的集合，使用圆括号`()`构造，其中元素由逗号`,`分隔。
元素的顺序很重要，例如`(1, true)`和`(true, 1)`是不同的类型。以下是一个例子：

```rust live
fn pack(a: Bool, b: Int, c: String, d: Float) -> (Bool, Int, String, Float) {
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
    "yes".print()
  } else {
    "no".print()
  }
}

fn init {
  f((1, 2))
}
```

### 数组

数组是由方括号`[]`构造的有限值序列，其中元素由逗号`,`分隔。例如：

```rust
let array = [1, 2, 3, 4]
```

可以使用`array[x]`来引用第 x 个元素。索引从零开始。

```rust live
fn init {
  let array = [1, 2, 3, 4]
  let a = array[2]
  array[3] = 5
  let b = a + array[3]
  b.print() // prints 8
}
```

## 变量绑定

变量可以使用关键字`var`或`let`分别声明为可变或不可变。
可变变量可以重新赋值，不可变变量则不能。

```rust live
let zero = 0

fn init {
  var i = 10
  i = 20
  (i + zero).print()
}
```

对于局部不可变绑定，还可以使用`:=`的简写语法糖。

```rust live
fn init {
  a := 3
  b := "hello"
  print(a)
  print(b)
}
```

## 数据类型

创建新数据类型的方法有两种：`struct`和`enum`。

### 结构

在 MoonBit 中，结构与元组类似，但是它们的字段由字段名索引。
结构体可以使用结构体字面量构造，结构体字面量由一组带有标签的值组成，并用花括号括起来。
如果结构体字面量的字段完全匹配类型定义，则其类型可以被自动推断。
使用点语法 s.f 可以访问结构体字段。
如果一个字段使用关键字 mut 标记为可变，那么可以给它赋予新的值。

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

## 模式匹配

我们已经展示了对枚举进行模式匹配的用例，但是模式匹配不局限于枚举。
例如，我们也可以对布尔值、数字、字符、字符串、元组、数组和结构体字面量进行模式匹配。
由于这些类型和枚举不同，只有一种情况，我们可以使用`let`/`var`绑定而不是`match`表达式来对它们进行模式匹配。
需要注意的是，在`match`中绑定的变量的作用域仅限于引入该变量的分支，而`let`/`var`绑定将引入每个变量到当前作用域。
此外，我们可以使用下划线 `_` 作为我们不关心的值的通配符。

```rust
let id = match u {
  { id: id, name: _, email: _ } => id
}
// is equivalent to
let { id: id, name: _, email: _ } = u
```

在模式匹配中还有一些其他有用的构造。
例如，我们可以使用`as`为某个模式指定一个名称，并且可以使用`|`同时匹配多个情况。

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
我们可以重写前面提到的数据类型`List`，添加类型参数`T`，以获得一个泛型版本的列表。
然后，我们可以定义泛型函数`map`和`reduce`，用于对列表进行操作。

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

## 统一函数调用语法

MoonBit 支持与传统面向对象语言不同的方法(method)。
一个方法被定义为`self`作为其第一个参数的顶层函数。
`self`参数将成为方法调用的主体。
例如，`l.map(f)`等同于`map(l, f)`。
这种语法使得方法链而不是嵌套的函数调用成为可能。
例如，我们可以使用这样的语法将先前定义的`map`和`reduce`与`from_array`和`output`方法链在一起，执行列表操作。

```rust live
fn map[S, T](self: List[S], f: (S) -> T) -> List[T] {
  match self {
    Nil => Nil
    Cons(x, xs) => Cons(f(x), map(xs, f))
  }
}

fn reduce[S, T](self: List[S], op: (T, S) -> T, init: T) -> T {
  match self {
    Nil => init
    Cons(x, xs) => reduce(xs, op, op(init, x))
  }
}

fn into_list[T](self: Array[T]) -> List[T] {
  var res: List[T] = Nil
  var i = self.length() - 1
  while (i >= 0) {
    res = Cons(self[i], res)
    i = i - 1
  }
  res
}

fn init {
  print([1, 2, 3, 4, 5].into_list().map(fn(x) { x * 2 }).reduce(fn(x, y) { x + y }, 0))
}
```

方法和普通函数的另一个区别是，只有方法支持重载。
例如，我们可能需要多个输出函数：`output_int`和`output_float`用于不同类型的输出。
但使用方法`output`，可以识别主体的类型，并选择适当的重载版本，例如 1.print()和 1.0.print()。

## 运算符重载

MoonBit 支持重载内置运算符。与运算符`<op>`相对应的方法名称是`op_<op>`。例如：

```rust live
struct T {
  x:Int
}

fn op_add(self: T, other: T) -> T {
  { x: self.x + other.x }
}

fn init {
  let a = { x:0, }
  let b = { x:2, }
  print((a + b).x)
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

## 访问控制

默认情况下，所有函数定义和变量绑定对其他包是 _不可见_ 的；
没有修饰符的类型是抽象数据类型，其名称被导出，但内部是不可见的。
这种设计防止了意外暴露实现细节。
您可以在`type`/`fn`/`let`前使用`pub`修饰符使其完全可见，或在`type`前使用`priv`修饰符使其对其他包完全不可见。
您还可以在字段名前使用`pub`或`priv`获得更细粒度的访问控制。
但是，请注意：

- 在抽象或私有结构体内，所有字段都不能被定义为`pub`，因为这样没有意义。
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

MoonBit 中另一个有用的特性是 `pub(readonly)` 类型，其受到了 OCaml [private types](https://v2.ocaml.org/manual/privatetypes.html)的启发。简而言之，`pub(readonly)`类型的值可以使用模式匹配或点语法析构，但在其他包中，不能被构造或改变。注意到在`pub(readonly)`类型定义的同一个包中，它没有任何限制。

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
fn print(r : RO) {
  "{ field: ".print()
  r.field.print()  // OK
  " }".print()
}
fn init {
  let r : RO = { field: 4 }  // ERROR: Cannot create values of the public read-only type RO!
  let r = { ..r, field: 8 }  // ERROR: Cannot mutate a public read-only field!
}
```

MoonBit 中的访问控制遵循这样一个原则：`pub`类型、函数或变量不能基于私有类型进行定义。
这是因为私有类型可能不是在使用`pub`实体的所有地方都可以被访问。
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

## 接口系统

MoonBit 具有用于重载/特设多态的结构接口系统。
接口可以声明如下：

```rust
interface I {
  f(Self, ...) -> ...
}
```

无需显式实现接口。
具有所需方法的类型会自动实现接口。
例如，以下接口：

```rust
interface Show {
  to_string(Self) -> String
}
```

内置类型如 `Int` 和 `Float` 会自动实现这个接口。

在声明泛型函数/方法时，类型参数可以用它们应该实现的接口进行注解。
例如：

```rust
interface Number {
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
  print(square(2)) // 4
  print(square(1.5)) // 2.25
  print(square({ x: 2, y: 3 })) // (4, 9)
}

struct Point {
  x: Int
  y: Int
}

fn op_add(self: Point, other: Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

fn op_mul(self: Point, other: Point) -> Point {
  { x: self.x * other.x, y: self.y * other.y }
}

fn to_string(self: Point) -> String {
  let x = self.x
  let y = self.y
  "(\(x), \(y))"
}
```

Moonbit provides the following useful builtin interfaces:

```rust
interface Eq {
  op_equal(Self, Self) -> Bool
}

interface Compare {
  // `0` for equal, `-1` for smaller, `1` for greater
  op_equal(Self, Self) -> Int
}

interface Hash {
  hash(Self) -> Int
}

interface Show {
  to_string(Self) -> String
}

interface Default {
  Self::default() -> Self
}
```

## 没有 self 参数的方法

有时候，拥有不带 self 参数的方法非常有用。例如，内置的 `Default` 接口描述了具有默认值的类型，但构造默认值不应该依赖于 self 值。因此，MoonBit 提供了一种特殊的语法用于不带 self 参数的方法：

```rust live
fn Int::default() -> Int {
  0
}

fn init {
  print(Int::default())
}
```

没有 `self` 的方法必须显式使用它们的类型名称进行调用。
没有 `self` 的方法可以在接口中声明，并使用类型参数进行调用，例如：

```rust
interface I {
  Self::one() -> Self
  op_add(Self, Self) -> Self
}

fn two[X: I]() -> X {
  X::one() + X::one()
}
```

## MoonBit 的构建系统

构建系统的介绍可以在 [MoonBit 的构建系统教程](./build-system-tutorial.md) 中找到。
