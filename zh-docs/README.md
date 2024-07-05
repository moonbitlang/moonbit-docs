# MoonBit

MoonBit 是一个用于云计算和边缘计算的 WebAssembly 端到端的编程语言工具链。
您可以访问 https://try.moonbitlang.cn 获得 IDE 环境，无需安装任何软件，也不依赖任何服务器。

## 状态

MoonBit 目前处于 Pre-alpha 阶段，是实验性质的。我们期望今年能达到 beta 阶段。

## 主要优势

- 生成比现有解决方案明显更小的 WASM 文件。
- 更高的运行时性能。
- 先进的编译时性能。
- 简单且实用的数据导向语言设计。

## 概述

一个月兔程序由类型定义，函数定义和变量绑定组成。
每个包的入口点是一个特殊的 `init` 函数，它有以下两个特点：

1. 同一个包中可以有多个 `init` 函数。
2. `init` 函数不能被显式调用或被其他函数引用。相反，在一个包初始化时，所有的 `init` 函数都将被隐式地调用。因此，`init` 函数中只能包含语句。

```moonbit live
fn init {
  print("Hello world!") // OK
}

fn init {
  let x = 1
  // x     // 失败
  print(x) // 成功
}
```

MoonBit 区分语句和表达式。在一个函数体中，只有最后一句才能写成作为返回值的表达式。例如：

```moonbit live
fn foo() -> Int {
  let x = 1
  x + 1 // OK
}

fn bar() -> Int {
  let x = 1
  x + 1 // 失败
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
- 算术、逻辑和比较运算
- 访问数组元素（例如 `a[0]`）、结构体字段（例如 `r.x`）或元组的元素（例如 `t.0`）
- 变量和（大写字母开头的）枚举构造器
- 匿名局部函数定义
- `match` 和 `if` 表达式

语句包括：

- 命名局部函数定义
- 局部变量绑定
- 赋值
- `return` 语句
- 返回类型为 `unit` 的任何表达式

## 函数

函数接受参数并产生结果。
在 MoonBit 中，函数是一等公民，这意味着函数可以作为其他函数的参数或返回值。

### 顶层函数

函数可以被定义为顶层或局部。
我们可以使用 `fn` 关键字定义一个顶层函数，
例如以下函数求三个整数之和并返回结果：

```moonbit
fn add3(x: Int, y: Int, z: Int)-> Int {
  x + y + z
}
```

注意，顶层函数的参数和返回值类型需要显式标注。

### 局部函数

局部函数使用 `fn` 关键字定义。局部函数可以是命名的或匿名的。在大多数情况下，局部函数的类型注解可以省略，因为编译器可以自动推断。例如：

```moonbit live
fn foo() -> Int {
  fn inc(x) { x + 1 }       // 命名为 `inc`
  fn (x) { x + inc(2) } (6) // 匿名，立即应用到整数字面量 6
}

fn init {
  print(foo())
}
```

无论是命名的还是匿名的，函数都是 _词法闭包_：任何没有局部绑定的标识符，
必须引用来自周围词法作用域的绑定：

```moonbit live
let y = 3
fn foo(x: Int) -> Unit {
  fn inc()  { x + 1 } // OK，返回 x + 1
  fn four() { y + 1 } // Ok，返回 4
  print(inc())
  print(four())
}

fn init {
  foo(2)
}
```

### 函数调用

函数可通过向圆括号内传入参数列表进行调用：

```moonbit
add3(1, 2, 7)
```

这适用于命名函数（如前面的例子）和绑定到函数值的变量，如下所示：

```moonbit live
fn init {
  let add3 = fn(x, y, z) { x + y + z }
  print(add3(1, 2, 7))
}
```

表达式 `add3(1, 2, 7)` 返回 `10`。任何求值为函数值的表达式都可以被调用：

```moonbit live
fn init {
  let f = fn (x) { x + 1 }
  let g = fn (x) { x + 2 }
  print((if true { f } else { g })(3)) // OK
}
```

### 带标签的参数

可以用 `~label : Type` 的语法为函数声明带标签的参数。函数体内参数的名字也是 `label`：

```moonbit
fn labelled(~arg1 : Int, ~arg2 : Int) -> Int {
  arg1 + arg2
}
```

调用函数时，可以用 `label=arg` 的语法提供带标签的参数。`label=label` 可以简写成 `~label`：

```moonbit
fn init {
  let arg1 = 1
  println(labelled(arg2=2, ~arg1)) // 3
}
```

可以用任意的顺序提供带标签的参数。参数的求值顺序与函数声明中参数的顺序相同。

### 可选的参数

可选的参数是带有默认值的带标签参数。声明可选的参数的语法是 `~label : Type = default_expr`。调用函数时，如果没有提供这个参数，就会使用默认值作为参数：

```moonbit live
fn optional(~opt : Int = 42) -> Int {
  opt
}

fn init {
  println(optional()) // 42
  println(optional(opt=0)) // 0
}
```

每次使用默认参数调用一个函数时，都会重新求值默认值的表达式，也会被重新触发其中的副作用。例如：

```moonbit live
fn incr(~counter : Ref[Int] = { val: 0 }) -> Ref[Int] {
  counter.val = counter.val + 1
  counter
}

fn init {
  println(incr()) // 1
  println(incr()) // 依然是 1，因为重新求值了默认表达式，产生了一个新的 Ref
  let counter : Ref[Int] = { val: 0 }
  println(incr(~counter)) // 1
  println(incr(~counter)) // 2，因为两次调用使用了同一个 Ref
}
```

如果想要在多次不同的函数调用之间共享默认值，可以提前用 `let` 计算并保存默认值：

```moonbit live
let default_counter : Ref[Int] = { val: 0 }

fn incr(~counter : Ref[Int] = default_counter) -> Int {
  counter.val = counter.val + 1
  counter.val
}

fn init {
  println(incr()) // 1
  println(incr()) // 2
}
```

默认值可以依赖于前面的参数，例如：

```moonbit
fn sub_array[X](xs : Array[X], ~offset : Int, ~len : Int = xs.length() - offset) -> Array[X] {
  ... // 生成 xs 的一个从 offset 开始、长度为 len 的子数组
}

fn init {
  println(sub_array([1, 2, 3], offset=1)) // [2, 3]
  println(sub_array([1, 2, 3], offset=1, len=1)) // [2]
}
```

### 自动填充的参数

MoonBit 能够自动在每次函数调用时填充某些特定类型的参数，例如函数调用在源码中的位置。要声明这种自动填充的参数，只需要使用 `_` 作为参数的默认值即可。如果在调用时没有提供这个参数，MoonBit 就会自动根据调用处的上下文填充这个参数。

目前 MoonBit 支持两种类型的自动填充参数。代表整个函数调用在源码中位置的 `SourceLoc` 类型，以及包含每个参数各自的位置的 `ArgsLoc` 类型：

```moonbit
fn f(_x : Int, _y : Int, ~loc : SourceLoc = _, ~args_loc : ArgsLoc = _) -> Unit {
  println("整个函数调用的位置：\(loc)")
  println("各个参数的位置：\(args_loc)")
}

fn init {
  f(1, 2)
  // 整个函数调用的位置：<文件名>:7:3-7:10
  // 各个参数的位置：[Some(<文件名>:7:5-7:6), Some(<文件名>:7:8-7:9), None, None]
}
```

自动填充的参数可以用于编写调试和测试用的工具函数。

## 控制结构

### 条件表达式

条件表达式由条件、结果和一个可选的 `else` 子句组成。

```moonbit
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

```moonbit
if x == y {
  expr1
} else if z == k {
  expr2
}
```

花括号用于在结果或 `else` 子句中组合表达式。

注意，在 MoonBit 中，条件表达式总是返回一个值，其结果和 `else` 子句的返回值类型必须相同。


### While 循环

MoonBit中支持`while`循环。`while`后的循环条件会在循环体之前执行，当循环条件为真时, 执行循环体：

```moonbit
let mut i = 5
while i > 0 {
  println(i)
  i = i - 1
}
```

循环体内支持`break`和`continue`。使用`break`能够跳出当前循环；使用`continue`跳过本次循环的剩余部分，提前进入下一次循环。


```moonbit 
let mut i = 5
while i > 0 {
  i = i - 1
  if i == 4 { continue }
  if i == 1 { break }
  println(i)
}
```

输出:

```
3
2
```

`while` 循环也支持可选的`else`子句。当循环条件转变为假时，将会执行`else`子句，然后循环结束。

```moonbit 
let mut i = 2
while i > 0 {
  println(i)
  i = i - 1
} else {
  println(i)
}
```

输出:

```
2
1
0
```

当存在 `else` 子句时，`while` 循环也可以返回一个值，返回值是 `else` 子句语句块的求值结果。此时如果使用`break`跳出循环，需要在`break`后提供一个返回值，类型与`else`子句的返回值类型一致：


```moonbit 
  let mut i = 10
  let r1 = 
    while i > 0 {
      i = i - 1
      if i % 2 == 0 { break 5 } // 跳出循环并返回 5
    } else {
      7
    }
  println(r1) //output: 5
```

```moonbit 
  let mut i = 10
  let r2 = 
    while i > 0 {
      i = i - 1
    } else {
      7
    }
  println(r2) //output: 7
```

## For 循环

MoonBit 也支持 C 风格的 For 循环。关键字`for`后依次跟随以分号间隔的变量初始化子句、循环条件和更新子句。三者不需要使用圆括号包裹。
例如下面的代码创建了一个新的变量绑定`i`, 它的作用域在整个循环中，且是不可变的。这更利于编写清晰的代码和推理：

```moonbit
for i = 0; i < 5; i = i + 1 {
  println(i)
} 
// output:
// 0
// 1
// 2
```

变量初始化子句中可以创建多个绑定：

```moonbit
for i = 0, j = 0; i + j < 100; i = i + 1, j = j + 1 {
  println(i)
}
```

需要注意的是在更新子句中，对于多个绑定变量具有同时更新的语义。也就是说上面的例子中，更新子句并不是顺序执行`i = i + 1`、`j = j + 1`，而是同时令`i`、`j`自增。因此，在更新子句中读取绑定变量得到的值永远是上一次循环更新后的值。



变量初始化子句、循环条件和更新子句都是可选的。例如下面两个无限循环：

```moonbit
for i=1;; i=i+1 {
  println(i) // loop forever!
}
```

```moonbit
for {
  println("loop forever!")
}
```

`for` 循环同样支持`continue`、`break`和`else`子句。和`while`循环一样，`for` 循环同样
支持使用`break`和`else`子句使`for`语句返回一个值。

使用`continue`语句将跳过`for`本次循环的剩余部分（包括更新子句）提前进入下次循环。`continue`语句
也支持同时更新`for`循环的绑定变量，只要在`continue`后面跟随和绑定变量数量一致的表达式，多个表达式使用逗号分隔。

例如，下面的程序计算数字1到6中的偶数的和：

```moonbit live
fn main {
  let sum =
    for i = 1, acc = 0; i <= 6; i = i + 1 {
      if i % 2 == 0 {
        println("even: \(i)")
        continue i + 1, acc + i
      }
    } else {
      acc
    }
  println(sum)
}
```

输出：

```
even: 2
even: 4
even: 6
12
```

### 函数式循环

函数式循环是 MoonBit 中一个强大的特性，它能让您以函数式风格编写循环。

函数式循环接受参数并返回一个值。它使用 `loop` 关键字定义，后跟其参数和循环体。
循环体是一系列子句，每个子句由模式和表达式组成。
与输入匹配的模式会被执行，并且循环将返回表达式的值。如果没有匹配的模式，循环将抛出异常。
可以使用 `continue` 关键字和参数开始下一次循环迭代，使用 `break` 关键字和参数来从循环中返回一个值。
如果值是循环体中的最后一个表达式，则可以省略 `break` 关键字。

```moonbit live
fn sum(xs: List[Int]) -> Int {
  loop xs, 0 {
    Nil, acc => break acc // break 可以省略
    Cons(x, rest), acc => continue rest, x + acc
  }
}

fn init {
  println(sum(Cons(1, Cons(2, Cons(3, Nil)))))
}
```

## 内置数据结构

### 布尔值

MoonBit 内置了布尔类型，它有两个值：`true` 和 `false`。布尔类型用于条件表达式和控制结构。

```moonbit
let a = true
let b = false
let c = a && b
let d = a || b
let e = not(a)
```

### 数字

MoonBit 支持整型和浮点类型：

| 类型     | 描述                         |   例子   |
| -------- | ---------------------------- | ------- |
| `Int`    | 32 位有符号整数              | `42`      |
| `Int64`  | 64 位有符号整数              | `1000L`   |
| `UInt`   | 32 位无符号整数              ｜`14U`     |
| `UInt64` | 64 位无符号整数              | `14UL`   |
| `Double` | 64 位浮点数，由 IEEE754 定义 | `3.14`    |

MoonBit 支持的数字字面量，包括十进制、二进制、八进制和十六进制。

为了提升可读性，你可以在数字字面量内插入下划线，例如 `1_000_000`。
注意，下划线可以插入到数字之间的任何位置，而非只能在每三个数字之间。

- 十进制数和往常一样。

```moonbit
let a = 1234
let b = 1_000_000 + a
let large_num = 9_223_372_036_854_775_807L // Int64 类型的整数必须后缀“L”
let unsigned_num = 4_294_967_295U // UInt 类型的整数必须有后缀”U“
```

- 八进制数的前缀是 0 后接字母 O，也就是 `0o` 或 `0O`。注意在 `0o` 或 `0O`
  之后出现的数字只能在 `0` 到 `7` 之间。

```moonbit
let octal = 0o1234
let another_octal = 0O1234
```

- 十六进制数的前缀是 0 后接字母 X，也就是 `0x` 或 `0X`。注意在 `0x` 或 `0X`
  之后出现的数字只能是 `0123456789ABCDEF` 之一。

```moonbit
let hex = 0XA
let another_hex = 0xA
```

### 字符串

字符串`String`内部保存了 UTF-16 编码单元序列。可以使用双引号来表示一个字符串，或者通过`#|`来书写多行字符串。

```moonbit
let a = "兔rabbit"
println(a[0]) // output: 兔
println(a[1]) // output: r
```

```moonbit
let b =
  #| Hello
  #| MoonBit
  #|
```

在双引号包围的字符串之间支持使用`\`表示特殊字符转义：

| 转义序列             | 解释                         |
| -------------------- | ---------------------------- |
| `\n`,`\r`,`\t`,`\b`  | 换行、回车、水平制表符、退格 |
| `\\`                 | 反斜杠                       |
| `\x41`               | 16 进制转义序列              |
| `\o102`              | 8 进制转义序列               |
| `\u5154`,`\u{1F600}` | Unicode 字符转义序列         |

MoonBit 支持字符串插值，它可以把字符串中内插的变量替换为变量具体的值。
这个特性能够简化动态拼接字符串的过程。

```moonbit live
fn init {
  let x = 42
  print("The answer is \(x)")
}
```

用于字符串内插的变量必须支持 `to_string` 方法。

### 字符

字符`Char`是表示一个 Unicode 字符的整数。

```moonbit
let a : Char = 'A'
let b = '\x41'
let c = '🐰'
let zero = '\u{30}'
let zero = '\u0030'
```

### 字节

在 MoonBit 中，字节字面量可以是一个 ASCII 字符或一个转义序列，它们被单引号`'`包围，并且前面有字符`b`。字节字面量的类型是 Byte。例如：

```moonbit live
fn init {
  let b1 : Byte = b'a'
  println(b1.to_int())
  let b2 = b'\xff'
  println(b2.to_int())
}
```

### 元组

元组是一个有限值的有序集合，使用圆括号 `()` 构造，其中的元素由逗号 `,` 分隔。
元素的顺序很重要，例如 `(1, true)` 和 `(true, 1)` 是不同的类型。以下是一个例子：

```moonbit live
fn pack(a: Bool, b: Int, c: String, d: Double) -> (Bool, Int, String, Double) {
    (a, b, c, d)
}
fn init {
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
    println("\(bool_val) \(int_val) \(str) \(float_val)")
}
```

可以通过模式匹配或索引来访问元组：

```moonbit live
fn f(t : (Int, Int)) -> Unit {
  let (x1, y1) = t  // 通过模式匹配访问
  // 通过索引访问
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

```moonbit
let numbers = [1, 2, 3, 4]
```

可以用 `numbers[x]` 来引用第 `x` 个元素。索引从零开始。

```moonbit live
fn init {
  let numbers = [1, 2, 3, 4]
  let a = numbers[2]
  numbers[3] = 5
  let b = a + numbers[3]
  print(b)  // 打印 8
}
```

## 变量绑定

变量可以通过 `let mut` 或 `let` 分别声明为可变或不可变。
可变变量可以重新赋值，不可变变量则不能。

```moonbit live
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

在 MoonBit 中，结构与元组类似，但它们的字段由字段名索引。
结构体可以使用结构体字面量构造，结构体字面量由一组带有标签的值组成，并用花括号括起来。
如果结构体字面量的字段完全匹配类型定义，则其类型可以被自动推断。
使用点语法 `s.f` 可以访问结构体字段。
如果一个字段使用关键字 `mut` 标记为可变，那么可以给它赋予新的值。

```moonbit live
struct User {
  id: Int
  name: String
  mut email: String
}

fn init {
  let u = { id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  println(u.id)
  println(u.name)
  println(u.email)
}
```

#### 创建结构体的简写形式

如果已经有和结构体的字段同名的变量，并且想使用这些变量作为结构体同名字段的值，
那么创建结构体时，可以只写字段名，不需要把同一个名字重复两次。例如：

```moonbit live
fn init{
  let name = "john"
  let email = "john@doe.com"
  let u = { id: 0, name, email } // 等价于 { id: 0, name: name, email: email }
}
```

#### 更新结构体的语法

如果想要基于现有的结构体来创建新的结构体，只需修改现有结构体的一部分字段，其他字段的值保持不变，
可以使用结构体更新语法：

```moonbit live
struct User {
  id: Int
  name: String
  email: String
} derive(Debug)

fn init {
  let user = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated_user = { ..user, email: "john@doe.name" }
  debug(user)          // 输出: { id: 0, name: "John Doe", email: "john@doe.com" }
  debug(updated_user)  // 输出: { id: 0, name: "John Doe", email: "john@doe.name" }
}
```

### 枚举

枚举类型对应于代数数据类型（Algebraic Data Type，ADT），
熟悉 C/C++ 的人可能更习惯叫它带标签的联合体（tagged union）。

枚举由一组分支（构造器）组成，每个分支都有一个名字（必须以大写字母开头），可以用这个名字来构造对应分支的值，
或者在模式匹配中使用这个名字来判断某个枚举值属于哪个分支：

```moonbit live
// 一个表示两个值之间的有序关系的枚举类型，有 “小于”、“大于”、“等于” 三个分支
enum Relation {
  Smaller
  Greater
  Equal
}

// 计算两个整数之间的顺序关系
fn compare_int(x: Int, y: Int) -> Relation {
  if x < y {
    // 创建枚举时，如果知道想要什么类型，可以直接写分支/构造器的名字来创建
    Smaller
  } else if x > y {
    // 但如果不知道类型，永远可以通过 `类型名字::构造器` 的语法来无歧义地创建枚举值
    Relation::Greater
  } else {
    Equal
  }
}

// 输出一个 `Relation` 类型的值
fn print_relation(r: Relation) -> Unit {
  // 使用模式匹配判断 r 属于哪个分支
  match r {
    // 模式匹配时，如果知道类型，直接使用构造器名字即可
    Smaller => println("smaller!")
    // 但也可以用 `类型名字::构造器` 的语法进行模式匹配
    Relation::Greater => println("greater!")
    Equal => println("equal!")
  }
}

fn init {
  print_relation(compare_int(0, 1)) // 输出 smaller!
  print_relation(compare_int(1, 1)) // 输出 equal!
  print_relation(compare_int(2, 1)) // 输出 greater!
}
```

枚举的分支还可以携带额外的数据。下面是用枚举定义整数列表类型的一个例子：

```moonbit live
enum List {
  Nil
  // 构造器 `Cons` 携带了额外的数据：列表的第一个元素，和列表剩余的部分
  Cons (Int, List)
}

fn init {
  // 使用 `Cons` 创建列表时，需要提供 `Cons` 要求的额外数据：第一个元素和剩余的列表
  let l: List = Cons(1, Cons(2, Nil))
  println(is_singleton(l))
  print_list(l)
}

fn print_list(l: List) -> Unit {
  // 使用模式匹配处理带额外数据的枚举时，除了判断值属于哪个分支，
  // 还可以把对应分支携带的数据提取出来
  match l {
    Nil => print("nil")
    // 这里的 `x` 和 `xs` 不是现有变量，而是新的变量。
    // 如果 `l` 是一个 `Cons`，那么 `Cons` 中携带的额外数据（第一个元素和剩余部分）
    // 会分别被绑定到 `x` 和 `xs`
    Cons(x, xs) => {
      print(x)
      print(",")
      print_list(xs)
    }
  }
}

// 除了变量，还可以对构造器中携带的数据进行进一步的匹配。
// 例如，下面的函数判断一个列表是否只有一个元素
fn is_singleton(l: List) -> Bool {
  match l {
    // 这个分支只会匹配形如 `Cons(_, Nil)` 的值，也就是长度为 1 的列表
    Cons(_, Nil) => true
    // 用 `_` 来匹配剩下的所有可能性
    _ => false
  }
}
```

#### 带标签的构造器参数

枚举构造器可以有带标签的参数：

```moonbit live
enum E {
  // `x` 和 `y` 是带标签的参数
  C(~x : Int, ~y : Int)
}

// 模式匹配有带标签参数的构造器
fn f(e : E) -> Unit {
  match e {
    // `标签=匹配参数的模式`
    C(x=0, y=0) => println("0!")
    // `~x` 是 `x=x` 的简写
    // 未被匹配的带标签参数可以用 `..` 来忽略
    C(~x, ..) => println(x)
  }
}

// 创建有带标签参数的构造器
fn init {
  f(C(x=0, y=0)) // `标签=参数的值`
  let x = 0
  f(C(~x, y=1)) // `~x` 是 `x=x` 的简写
}
```

在模式匹配中，还可以像访问结构体的字段一样直访问取构造器的带标签参数：

```moonbit live
enum Object {
  Point(~x : Double, ~y : Double)
  Circle(~x : Double, ~y : Double, ~radius : Double)
}

fn distance_with(self : Object, other : Object) -> Double {
  match (self, other) {
    // 如果通过 `Point(..) as p` 的方式定义一个变量 `p`，
    // 编译器知道 `p` 一定是构造器 `Point`，
    // 所以可以直接用 `p.x`、`p.y` 访问 `Point` 的带标签参数
    (Point(_) as p1, Point(_) as p2) => {
      let dx = p2.x - p1.x
      let dy = p2.y - p1.y
      (dx * dx + dy * dy).sqrt()
    }
    (Point(_), Circle(_)) | (Circle(_) | Point(_)) | (Circle(_), Circle(_)) => abort("not implemented")
  }
}

fn init {
  let p1 : Point = Point(x=0, y=0)
  let p2 : Point = Point(x=3, y=4)
  println(p1.distance_with(p2)) // 5.0
}
```

#### 构造器的可变字段

MoonBit 支持给构造器声明可变的字段。这对实现可变数据结构非常有用：

```moonbit live
// 一个带父节点指针的可变二叉搜索树的类型
enum Tree[X] {
  Nil
  // only labelled arguments can be mutable
  Node(mut ~value : X, mut ~left : Tree[X], mut ~right : Tree[X], mut ~parent : Tree[X])
}

// 一个使用可变的二叉搜索树实现的集合
struct Set[X] {
  mut root : Tree[X]
}

fn Set::insert[X : Compare](self : Set[X], x : X) -> Unit {
  self.root = self.root.insert(x, parent=Nil)
}

// 像一棵可变的二叉搜索树中插入一个新的元素。
// 返回插入后二叉搜索树新的根节点
fn Tree::insert[X : Compare](self : Tree[X], x : X, ~parent : Tree[X]) -> Tree[X] {
  match self {
    Nil => Node(value=x, left=Nil, right=Nil, ~parent)
    Node(_) as node => {
      let order = x.compare(node.value)
      if order == 0 {
        // 修改构造器中的字段
        node.value = x
      } else if order < 0 {
        // 这里在 `node` 和 `node.left` 之间创建了一个环
        node.left = node.left.insert(x, parent=node)
      } else {
        node.right = node.right.insert(x, parent=node)
      }
      // 这棵二叉树是非空的，所以根节点还是原来那个
      node
    }
  }
}
```

### 新类型

MoonBit 支持一种特殊的枚举类型，称为新类型（newtype）：

```moonbit
// `UserId` 是一个全新的类型，而且用户可以给 `UserId` 定义新的方法等
// 但与此同时，`UserId` 的内部表示和 `Int` 是完全一致的
type UserId Int
type UserName String
```

新类型和只有一个构造器（与类型同名）的枚举类型非常相似。
因此，可以使用构造器来创建新类型的值、使用模式匹配来提取新类型的内部表示：

```moonbit
fn init {
  let id: UserId = UserId(1)
  let name: UserName = UserName("John Doe")
  let UserId(uid) = id        // `uid` 的类型是 `Int`
  let UserName(uname) = name  // `uname` 的类型是 `String`
  println(uid)
  println(uname)
}
```

除了模式匹配，还可以使用 `.0` 提取新类型的内部表示：

```moonbit
fn init {
  let id: UserId = UserId(1)
  let uid: Int = id.0
  println(uid)
}
```

## 模式匹配

我们已经展示了如何对枚举进行模式匹配，但模式匹配并不仅限于枚举。
例如，我们也可以对布尔值、数字、字符、字符串、元组、数组和结构体字面量进行模式匹配。
由于这些类型和枚举不同，它们只有一种情况，因此我们可以直接使用 `let` 绑定来对它们进行模式匹配。
需要注意的是，在 `match` 中绑定的变量的作用域仅限于引入该变量的情况分支，而 `let`
绑定会将每个变量都引入到当前作用域。此外，我们可以使用下划线 `_` 作为我们不关心的值的通配符。

```moonbit
let id = match u {
  { id: id, name: _, email: _ } => id
}
// 等价于
let { id: id, name: _, email: _ } = u
```

模式匹配还有一些有用的构造。例如，我们可以使用 `as` 为某个模式指定一个名称，
并且可以使用 `|` 同时匹配多个情况。

```moonbit
match expr {
  Lit(n) as a => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  _ => ...
}
```

### 键值对模式匹配

MoonBit 允许模式匹配字典等具有键值对结构的数据结构：

```moonbit
match map {
  // 匹配键 "b" 存在的情况
  { "b": Some(_) } => ..
  // 匹配 "b" 不存在且 "a" 存在的情况，
  // 匹配成功时，把 "a" 的值绑定到 `x`
  { "b": None, "a": Some(x) } => ..
  // 编译器指出下列情况没有被匹配到：{ "b": None, "a": None }
}
```

- 如果要用字典模式匹配类型 `T`，必须给类型 `T` 实现方法 `op_get`。`op_get` 的类型必须是 `(Self, K) -> Option[V]`，其中 `K` 是键的类型，`V` 是值的类型
- 目前，字典模式的键部分必须是一个常量
- 字典模式永远是开放的：未被匹配到的键会被忽略
- 字典模式会被编译成高效的代码：每个键至多被查询一次

## 错误处理

函数的返回值类型中可以包含错误类型，用于表示函数可能返回的错误。比如如下函数声明表示函数 `div` 可能返回一个字符串类型的错误：

```moonbit
fn div(x: Int, y: Int) -> Int!String { 
  if y == 0 {
    raise "division by zero"
  }
  x / y
}
```

其中 `raise` 关键字用于中断函数的执行并返回一个错误。函数的错误处理有以下三种方式：

* 使用 `!!` 后缀来在发生错误的情况下直接 panic，比如
```moonbit
fn div_unsafe(x: Int, y: Int) -> Int {
  div(x, y)!! // 直接 panic
}
```

* 使用 `!` 后缀来在发生错误的情况下将错误直接重新抛出，比如
```moonbit
fn div_reraise(x: Int, y: Int) -> Int!String {
  div(x, y)! // 直接重新抛出错误
}
```

* 使用 `try` 和 `catch` 对错误进行捕获并处理，比如
```moonbit
fn div_with_default(x: Int, y: Int, default: Int) -> Int {
  try {
    div(x, y)!
  } catch {
    s => { println(s); default }
  }
}
```
其中 `try` 用于调用可能会抛出错误的函数，`catch` 用于对捕获的错误进行模式匹配并处理，如果没有捕获到错误则不会执行 `catch` 语句块。

在 MoonBit 中，错误类型和错误处理属于二等公民，因此错误类型只能出现在函数的返回值中，而不能作为变量的类型。使用后缀表达式 `!` 或 `!!` 进行的错误处理也只能在函数调用处进行，而不能在其他表达式中使用，合法的使用形式包括：
```moonbit
f(x)!
x.f()!
(x |> f)!
(x + y)!
```

此外，如果函数的返回值类型中包含错误类型，那么对该函数的调用必须使用 `!` 或 `!!` 进行错误处理，否则编译器会报错。

## 泛型

您可以在顶层的函数和数据结构定义中使用泛型。类型参数可以由方括号引入。
我们可以重写前面提到的数据类型 `List`，添加类型参数 `T`，以获得一个泛型版本的列表。
然后，我们可以定义泛型函数 `map` 和 `reduce`，用于对列表进行操作。

```moonbit
enum List[T] {
  Nil
  Cons(T, List[T])
}

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
```

## 访问控制

默认情况下，所有函数定义和变量绑定对其他包都是 _不可见_ 的；
没有修饰符的类型是抽象数据类型，其名称被导出，但内部是不可见的。
这种设计防止了意外暴露实现细节。
您可以在 `type`/`fn`/`let` 前使用 `pub` 修饰符使其完全可见，或在 `type`
前使用 `priv` 修饰符使其对其他包完全不可见。
您还可以在字段名前使用 `pub` 或 `priv` 获得更细粒度的访问控制。
但是，请注意：

- 在抽象或私有结构体内，所有字段都不能被定义为 `pub`，因为这样没有意义。
- 枚举类型的构造器没有单独的可见性，所以不能在它们前面使用 `pub` 或 `priv`

```moonbit
struct R1 {       // 默认为抽象数据类型
  x: Int          // 隐式的私有字段
  pub y: Int      // ERROR: 在抽象类型中找到了 `pub` 字段！
  priv z: Int     // WARNING: `priv` 是多余的！
}

pub struct R2 {       // 显式的公共结构
  x: Int              // 隐式的公共字段
  pub y: Int          // WARNING: `pub` 是多余的！
  priv z: Int         // 显式的私有字段
}

priv struct R3 {       // 显式的私有结构
  x: Int               // 隐式的私有字段
  pub y: Int           // ERROR: `pub` 字段出现在了私有类型中！
  priv z: Int          // WARNING: `priv` 是多余的！
}

enum T1 {       // 默认为抽象数据类型
  A(Int)        // 隐式的私有变体
  pub B(Int)    // ERROR: 无独立可见性！
  priv C(Int)   // ERROR: 无独立可见性！
}

pub enum T2 {       // 显式的公共枚举
  A(Int)            // 隐式的公共变体
  pub B(Int)        // ERROR: 无独立可见性！
  priv C(Int)       // ERROR: 无独立可见性！
}

priv enum T3 {       // 显式的私有枚举
  A(Int)             // 隐式的私有变体
  pub B(Int)         // ERROR: 无独立可见性！
  priv C(Int)        // ERROR: 无独立可见性！
}
```

MoonBit 中另一个有用的特性是 `pub(readonly)` 类型，其受到了 OCaml [private types](https://v2.ocaml.org/manual/privatetypes.html)的启发。简而言之，`pub(readonly)` 类型的值可以使用模式匹配或点语法析构，但在其他包中，不能被构造或改变。注意到在 `pub(readonly)` 类型定义的同一个包中，它没有任何限制。

```moonbit
// Package A
pub(readonly) struct RO {
  field: Int
}
fn init {
  let r = { field: 4 }       // OK
  let r = { ..r, field: 8 }  // OK
}

// Package B
fn print_RO(r : RO) -> Unit {
  print("{ field: ")
  print(r.field)  // OK
  print(" }")
}
fn init {
  let r : RO = { field: 4 }  // ERROR: 无法创建公共只读类型 RO 的值！
  let r = { ..r, field: 8 }  // ERROR: 无法修改一个公共只读字段！
}
```

MoonBit 中的访问控制遵循这样一个原则：`pub` 类型、函数或变量不能基于私有类型定义。
这是因为私有类型可能不是在使用 `pub` 实体的所有地方都可以被访问。
MoonBit 内建了一些检查，以防止违反这一原则的用例。

```moonbit
pub struct s {
  x: T1  // OK
  y: T2  // OK
  z: T3  // ERROR: 公共字段拥有私有类型 `T3`！
}

// ERROR: 公共函数拥有私有形参类型 `T3`！
pub fn f1(_x: T3) -> T1 { T1::A(0) }
// ERROR: 公共函数拥有私有返回类型 `T3`！
pub fn f2(_x: T1) -> T3 { T3::A(0) }
// OK
pub fn f3(_x: T1) -> T1 { T1::A(0) }

pub let a: T3  // ERROR: 公共变量拥有私有类型 `T3`！
```

## 方法系统

MoonBit 支持与传统面向对象语言不同的方法（method）。
某个类型的方法就是与该类型关联的普通函数。
可以使用 `fn TypeName::method_name(...) -> ...` 的语法来为类型 `TypeName` 声明方法：

```moonbit
enum MyList[X] {
  Nil
  Cons(X, MyList[X])
}

fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> MyList[Y] { ... }
fn MyList::concat[X](xs: MyList[MyList[X]]) -> MyList[X] { ... }
```

如果一个函数的第一个参数名为 `self`，那么 MoonBit 会自动将这个函数定义为 `self` 的类型上的方法：

```moonbit
fn map[X, Y](self: MyList[X], f: (X) -> Y) -> List[Y] { ... }
// 等价于
fn MyList::map[X, Y](xs: MyList[X], f: (X) -> Y) -> List[Y] { ... }
```

方法就是某个类型所拥有的普通函数。所以，在没有歧义时，它们也可以像普通函数一样调用：

```moonbit
fn init {
  let xs: MyList[MyList[_]] = ...
  let ys = concat(xs)
}
```

但和普通函数不同，方法支持重载。不同的类型可以有同名的方法。
如果当前作用域内有多个同名方法，依然可以通过加上 `TypeName::` 的前缀来显式地调用一个方法：

```moonbit live
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

MoonBit 支持通过方法重载内置运算符。与运算符 `<op>` 相对应的方法名是 `op_<op>`。例如：

```moonbit live
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

另一个例子（关于`op_get`和`op_set`）:

```moonbit live
struct Coord {
  mut x: Int
  mut y: Int
} derive(Debug)

fn op_get(self: Coord, key: String) -> Int {
  match key {
    "x" => self.x
    "y" => self.y
  }
}

fn op_set(self: Coord, key: String, val: Int) -> Unit {
    match key {
    "x" => self.x = val
    "y" => self.y = val
  }
}

fn init {
  let c = { x: 1, y: 2 }
  debug(c)
  debug(c["y"])
  c["x"] = 23
  debug(c)
  debug(c["x"])
}
```

目前，以下运算符可以被重载：

| 运算符名称            | 方法名       |
| --------------------- | ------------ |
| `+`                   | `op_add`     |
| `-`                   | `op_sub`     |
| `*`                   | `op_mul`     |
| `/`                   | `op_div`     |
| `%`                   | `op_mod`     |
| `=`                   | `op_eual`    |
| `-`（一元运算符）       | `op_neg`     |
| `_[_]`（获取项）       | `op_get`     |
| `_[_] = _`（设置项）   | `op_set`     |
| `_[_.._]`（视图）      | `op_as_view` | 

## 管道运算符

MoonBit 提供了便利的管道运算符 `|>`，可以用于链式调用普通函数：

```moonbit
fn init {
  x |> f     // 等价于 f(x)
  x |> f(y)  // 等价于 f(x, y)

  // 分布在多行的链式调用
  arg_val
  |> f1 // 等价于 f1(arg_val)
  |> f2(other_args) // 等价于 f2(f1(arg_val), other_args)
}
```

## 视图

类似于其他语言的“切片”，视图能够引用数组等数据类型中的片段。可以使用`data[start..end]`的方式创建一个关于数组`data`的视图，这个视图引用了从下标`start`开始到`end`（不包含`end`）的元素。`start`和`end`也可以省略:

```moonbit
fn init {
  let xs = [0,1,2,3,4,5]
  let s1 : ArrayView[Int] = xs[2..]
  print_array_view(s1)            //output: 2345
  xs[..4]  |> print_array_view()  //output: 0123
  xs[2..5] |> print_array_view()  //output: 234
  xs[..]   |> print_array_view()  //output: 012345

  // 创建一个视图的视图
  xs[2..5][1..] |> print_array_view() //output: 34
}

fn print_array_view[T : Show](view : ArrayView[T]) -> Unit {
  for i=0; i<view.length(); i = i + 1 {
    print(view[i])
  }
  print("\n")
}
```

要为自定义数据类型添加视图支持，需要为它实现`length`和`op_as_view`方法。下面是一个例子：

```moonbit
struct MyList[A] {
  elems : Array[A]
} 

struct MyListView[A] {
  ls : MyList[A]
  start : Int
  end : Int
}

pub fn length[A](self : MyList[A]) -> Int {
  self.elems.length()
}

pub fn op_as_view[A](self : MyList[A], ~start : Int, ~end : Int) -> MyListView[A] {
  println("op_as_view: [\(start),\(end))")
  if start < 0 || end > self.length() { abort("index out of bounds") }
  { ls: self, start, end }
}

fn init {
  let ls = { elems: [1,2,3,4,5] }
  ls[..] |> ignore()
  ls[1..] |> ignore()
  ls[..2] |> ignore()
  ls[1..2] |> ignore()
}
```

输出：

```
op_as_view: [0,5)
op_as_view: [1,5)
op_as_view: [0,2)
op_as_view: [1,2)
```

## 接口系统

MoonBit 具有用于重载/特设多态（ad-hoc polymorphism）的结构接口系统。
接口描述了满足该接口的类型需要支持哪些操作。接口的声明方式如下：

```moonbit
trait I {
  f(Self, ...) -> ...
}
```

在接口声明中，`Self` 指代实现接口的那个类型。

一个类型要实现某个接口，就要满足该接口中所有的方法。例如，下面的接口描述了一个能够比较元素是否相等的类型需要满足的方法：

```moonbit
trait Eq {
  op_equal(Self, Self) -> Bool
}
```

接口无需显式实现，具有所需方法的类型会自动实现接口。考虑以下接口：

```moonbit
trait Show {
  to_string(Self) -> String
}
```

内置类型如 `Int` 和 `Double` 会自动实现这个接口。

在声明泛型函数时，类型参数可以用它们应该实现的接口作为注解。
如此便能定义只对某些类型可用的泛型函数。例如：

```moonbit
trait Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

fn square[N: Number](x: N) -> N {
  x * x
}
```

如果没有 `Number` 的要求，`square` 中的表达式 `x * x` 会导致出现找不到方法/运算符的错误。
现在，函数 `square` 可以与任何实现了 `Number` 接口的类型一起使用，例如：

```moonbit live
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

接口中的方法可以用 `Trait::method` 的语法来直接调用。MoonBit 会推导 `Self` 的具体类型，
并检查 `Self` 是否实现了 `Trait`：

```moonbit live
fn init {
  println(Show::to_string(42))
  debug(Compare::compare(1.0, 2.5))
}
```

Moonbit 提供了以下实用的内建接口：

```moonbit
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
  debug_write(Self, Buffer) -> Unit
}
```

## 方法的访问权限控制与拓展方法

为了使 MoonBit 的接口系统具有一致性（coherence，即任何 `Type: Trait` 的组合都有全局唯一的实现），
防止第三方包意外地修改现有程序的行为，**只有类型所在的包能为它定义方法**。
所以用户无法为内建类型或来自第三方包的类型定义方法。

然而，我们有时也会需要拓展一个现有类型的功能，因此，MoonBit 提供了一种名为拓展方法的机制。
拓展方法可以通过 `fn Trait::method_name(...) -> ...` 的形式声明，
它们通过实现接口来拓展现有类型的功能。例如，假设要为内建类型实现一个新的接口
`ToMyBinaryProtocol`，就可以（且必须）使用拓展方法：

```moonbit
trait ToMyBinaryProtocol {
  to_my_binary_protocol(Self, Buffer) -> Unit
}

fn ToMyBinaryProtocol::to_my_binary_protocol(x: Int, b: Buffer) -> Unit { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: Double, b: Buffer) -> Unit { ... }
fn ToMyBinaryProtocol::to_my_binary_protocol(x: String, b: Buffer) -> Unit { ... }
```

在搜索某个接口的实现时，拓展方法比普通方法有更高的优先级，
因此拓展方法还可以用来覆盖掉行为不能满足要求的现有方法。
拓展方法只能被用于实现指定的接口，不能像普通的方法一样被直接调用。
此外，**只有类型或接口所在的包可以定义拓展方法**。
例如，只有 `@pkg1` 和 `@pkg2` 能为类型 `@pkg2.Type` 定义拓展方法 `@pkg1.Trait::f`。
这一限制使得 MoonBit 的接口系统在加入拓展方法这一灵活的机制后，仍能保持一致。

如果需要直接调用一个拓展方法，可以使用 `Trait::method` 语法。例如：

```moonbit live
trait MyTrait {
  f(Self) -> Unit
}

fn MyTrait::f(self: Int) -> Unit {
  println("Got Int \(self)!")
}

fn init {
  MyTrait::f(42)
}
```

## 自动实现内建接口

Moonbit 可以自动生成一些内建接口的实现:

```moonbit live
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

MoonBit 通过接口对象的形式来支持运行时多态。
假设 `t` 的类型为 `T`，且类型 `T` 实现了接口 `I`,
那么可以把 `T` 实现 `I` 的各个方法和 `t` 自己打包在一起，
创建一个 `I` 的接口对象 `t as I`。
接口对象擦除了值的具体类型，所以从不同的具体类型所创建的接口对象，
可以被封装在同一个数据结构里，统一进行处理：

```moonbit live
trait Animal {
  speak(Self)
}

type Duck String
fn Duck::make(name: String) -> Duck { Duck(name) }
fn speak(self: Duck) -> Unit {
  println(self.0 + ": quak!")
}

type Fox String
fn Fox::make(name: String) -> Fox { Fox(name) }
fn Fox::speak(_self: Fox) -> Unit {
  println("What does the fox say?")
}

fn init {
  let duck1 = Duck::make("duck1")
  let duck2 = Duck::make("duck2")
  let fox1 = Fox::make("fox1")
  let animals = [ duck1 as Animal, duck2 as Animal, fox1 as Animal ]
  let mut i = 0
  while i < animals.length() {
    animals[i].speak()
    i = i + 1
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

```moonbit
match t {
  None => { return None }
  Some(x) => x
}
```

被应用在表达式 `t : Result[T, E]` 上时，`t?` 等价于：

```moonbit
match t {
  Err(err) => { return Err(err) }
  Ok(x) => x
}
```

问号操作符可以用于优雅地组合多段可能失败或产生错误的程序：

```moonbit
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

## 测试块

MoonBit 提供了 `test` 代码块，用于编写测试用例，比如
```moonbit
test "test_name" {
  @test.eq(1 + 1, 2)!
  @test.eq(2 + 2, 4)!
}
```
`test` 代码块实际上是一个返回 `Unit` ，但是可能抛出 `String` 类型错误的函数（函数签名中记为 `Unit!String` ）。它会在执行 `moon test` 的过程中被调用，并通过构建系统输出测试报告。其中 `@test.eq` 是一个标准库中的函数，如果断言失败，会打印错误信息并终止测试。字符串 `"test_name"` 用于标识测试用例，是可选项，当其以 `"panic"` 开头时，表示该测试的期望行为是触发 panic，只有在 panic 被触发的情况下才能通过测试，比如：

```moonbit
test "panic_test" {
  let _ : Int = Option::None.unwrap()
}
```

## 文档注释

文档注释是以 `///` 开头的注释，出现在顶层结构（如 `fn`、`let`、`enum`、`struct`、`type`）的每一行前面。文档注释内包含 Markdown 文本和任意个注解。

```moonbit
/// Return a new array with reversed elements.
/// 
/// # Example
/// 
/// ```
/// reverse([1,2,3,4]) |> println()
/// ```
fn reverse[T](xs : Array[T]) -> Array[T] {
  ...
}
```

### 注解

注解是文档注释中 `@word ...` 形式的特殊注释。*word* 表示注解的类型，后面可以跟随多个 *word* 或字符串字面量，每条注解独占一行。在MoonBit中注解通常不会影响程序的含义。无法识别的注解将会触发警告。

- `@alert`注解

  当引用了被标记了`@alert`的函数时，编译器会触发相应的警告或者错误。这种机制提供了一种通用的方式，将函数标记为 `deprecated` 或 `unsafe`。

  它的形式为 `@alert category "alert message..."`。

  `category`表示`@alert`的类别，它可以是任意标识符。可以通过配置来决定哪些`alert`是启用的或者报告为错误。

  ```moonbit
  /// ...
  /// @alert deprecated "Use foo2 instead"
  pub fn foo() -> Unit { ... }

  /// ...
  /// @alert unsafe "Div will cause an error when y is zero"
  pub fn div(x: Int, y: Int) -> Int { ... } 

  fn main {
    foo() // warning: Use foo2 instead
    div(x, y) |> ignore // warning: Div will cause an error when y is zero
  }
  ```

## MoonBit 的构建系统

构建系统的介绍参见 [MoonBit 的构建系统教程](./build-system-tutorial.md)。
