## Moonbit 平台

Moonbit语言是专为WebAssembly和 JavaScript 而设计，提供 Native 等多后端支持的程序语言，是Moonbit平台的一个重要部分。当前(@2023年)Moonbit语言还处于早期阶段，语法特性和语义还没有完全确定，期待得到来自开源社区的反馈。

Moonbit语言的设计受到了Rust（强大的类型系统）以及Go语言（简洁、包管理、快速编译）的启发，只所以不直接沿用Rust或 Go语言，而设计Moonbit语言，是考虑到如下原因：

### 和Rust对比
1. Rust编译速度比较慢
2. Rust的宏、生命周期等复杂的语法特性，使得它的学习曲线对于多数应用开发者来说过于陡峭

### 和Go对比
1. 相比Go语言，Moonbit有更连贯的设计。表达能力也更强大，比如支持模式匹配以及Algebraic Data Types。
2. Moonbit是为WebAssembly设计的程序语言，设计之初就考虑全局优化，所以编译出来的WebAssembly体积极小，在内部测试中，Moonbit编译出的WebAssembly比Go语言编译的体积小1000倍以上。
3. 类型系统方面，Moonbit除了顶层(top level)定义需要标注类型，内部的实现都可以做到自动的类型推导。


## 语法

Moonbit语言结合学术界近20年沉淀，虽然语言内核是函数式，但是语法和普通命令式语言几乎一样，所以任何业界背景的人可以容易上手。

基本语法规则如下：

### init 函数
Moonbit语言 的 `init` 函数具有特殊的作用，它主要用于在程序启动前进行包级别的初始化。以下是init函数的一些特性:

- 在每个包中，可以定义多个 `init` 函数。
- `init` 函数不能被显示调用或引用，它会在包的初始化阶段自动执行。
- 包的初始化顺序遵循以下规则：
  - 首先初始化主包的导入包（按照它们在源代码中的导入顺序）。
  - 然后按照包中变量和 `init` 函数的声明顺序进行初始化。
  - 同一个包中的多个 `init` 函数按照它们在源代码中出现的顺序执行。
- `init` 函数通常用于调用其他函数、设置全局变量、初始化数据结构、注册类型或者执行其他一次性的配置操作。

示例:

```go
func init{
    "hello world".output()
}
```

### 函数

函数是用 `func` 关键字定义的，后面是函数名称、类型参数列表、值参数列表和可选返回类型。

示例:

```go
func sum_two(a : int, b : int): int {
    a + b
}

func max<T>(a : T, b : T): T{
    if a > b { a } else { b }
}
```

### Let绑定
Let绑定用于使用let关键字将一个模式绑定到一个表达式。该语言支持不可变（let）和可变（var）的绑定。

示例:

```go
let a : int = 100
var b : int = 0
func init{
    b = 20
    (a + b).output() // 120
}
```

### 条件表达式
条件表达式是用 `if` 关键字定义的，后面是一个表达式，然后是用大括号`{}`括起来的两个分支。

示例:

```go
func fib(x : int): int {
    if x > 2 { 
        fib(x-1) + fib(x-2) 
    } else {
        x
    }
}
```

### 循环
Moonbit语言 支持带有一个循环变量的 `while` 循环，以及用大括号`{}`括起来的循环体。

示例:

```go
func init{
    var i = 0;
    while i < 10 {
        i.output()
        i = i + 1
    }
}
```

### 模式匹配
模式匹配支持使用 `match` 关键字，后面是表达式和模式及其相关表达式的列表。

示例:

```go
// apply function `f` to each element of list, collect the results into a new list.
func map <X, Y> (self: list<X>, f: (X) => Y): list<Y> {
  match self {
  | Nil => Nil
  | Cons(x, rest) => Cons(f(x), map(rest, f))
  }
}
```

### 元组 tuple
Moonbit语言有原生的元组(tuple)，通过圆括号定义。

示例:

```go
func pack(a : bool, b : int, c : string, d : float) : (bool, int, string, float) {
    (a, b, c, d)
}
func init{
    let quad = pack(false, 100, "text", 3.14)
    let (bool_val, int_val, str, float_val) = quad
}
```

### enum 与 struct

struct与tuple类似，能够组合多个对应类型的值。不同的是struct需要给每个元素取一个名字。

```go
type User struct{
    id: int
    name: string
    email: string
}
```

enum与主流语言类似。 配合pattern matching能够方便地处理enum：

```go
type TreeKind enum{
    Node
    Leaf
}

var a : TreeKind = Leaf
func init{
    let str = match a{
    | Node => "node"
    | Leaf => "leaf"
    }
    str.output()
}
```

不同的是Moonbit语言的enum能够让枚举的每一种情况带上任意个值，这有点像一个带标签的Union：

```go
type tree enum{
    Node(tree, tree)
    Leaf(int)
}

func print_tree<T>(t : tree){
    match t{
    | Node(a,b) => 
        "(".output()
        print_tree(a)
        ", ".output()
        print_tree(b)
        ")".output()
    | Leaf(v) => 
        v.output()
    }
}

var a : tree = Node(Leaf(1), Leaf(2))

func init{
    print_tree(a) //output: (1, 2)
}
```


### 数组
Moonbit语言的数组通过方括号定义。

示例:

```rust
func init{
  let ary = [1,2,3,4]
  let a = ary[2]
  ary[3] = 5
  let b = a + ary[3]
  b.output() //ouput 8
}
```

