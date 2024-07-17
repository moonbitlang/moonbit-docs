# 实现 Haskell 求值语义（系列一）

在探索编程语言的世界中，我们不可避免地会遇到一个核心概念：惰性求值（Lazy Evaluation）。Haskell，作为一门纯函数式编程语言，有强大的惰性求值机制，这一机制不仅允许开发者编写出更加高效和简洁的代码，而且在处理大型数据集或复杂的数据流时，能提高程序的性能和响应速度。本文将通过探讨惰性求值机制，深入解析其工作原理及实现方式，进而探讨如何在MoonBit实现Haskell求值语义。

## **01 高阶函数与性能挑战**

对很多人来说，map,filter这样的高阶函数是很多人接触函数式编程的第一印象（虽然它远不止这些内容）。它们简化了很多列表处理任务，但另一个问题也随之显现，就是这样的高阶函数如果套太多性能会比较差（主要原因是需要多次遍历列表）。

这时候有一些人会想到，是不是可以让编译器利用一些高阶函数上的规律优化代码？例如：我们可以把map(f, map(g, list))改写成：

```rust
map(fn (x) { f(g(x)) }, list)

```

这当然很好，但这样的优化措施有其局限性，在面对更复杂的情况时就不能总是合并函数调用了。把所有处理都写在一个函数里可以避免重复遍历列表，但是这样子的可读性不好也不方便改。有没有相对折中一点的方案呢？

**惰性求值就是一种能够在这种场景下一定程度减少不必要成本的技术。**它可以只在某种数据结构内部提供（例如Java8增加的Stream类型，以及更早的Scheme语言中的stream），也可以将整个语言设计成惰性的（这一思路的代表者是上世纪80年代的Miranda语言以及后来的Haskell与Clean语言）。

让我们先看看惰性列表（Stream）如何在这样的情况下避免多次遍历。

## **02 惰性列表实现**

首先写出其类型定义：

```rust
enum Stream[T] {
  Empty
  Cons(T, () -> Stream[T])
}
```

和List[T]只有一处有真正的差别：Cons中存放余下列表的地方换成了一个无参数函数（按行话来讲叫thunk）。这就是惰性求值的简单实现：用一个thunk把不想现在就马上算出来的东西包裹起来。

我们还需要一个函数把常规列表转换成惰性列表：

```rust
fn Stream::fromList[T](l : List[T]) -> Stream[T] {
  match l {
    Nil => Empty
    Cons(x, xs) => Cons(x, fn () { Stream::fromList(xs) })
  }
}
```

这个函数不需要遍历整个列表来将它转化为Stream, 对于当前不急着要结果的运算（这里是Stream::fromList(xs)）， 我们直接将其包裹在thunk里返回。接下来的map函数也会采用这个思路（不过这里的xs已经是thunk了）。

```rust
fn stream_map[X, Y](self : Stream[X], f : (X) -> Y) -> Stream[Y] {
  match self {
    Empty => Empty
    Cons(x, xs) => Cons(f(x), fn () { xs().stream_map(f) })
  }
}
```

take函数负责执行运算，它可以按需取出n个元素。

```rust
fn take[T](self : Stream[T], n : Int) -> List[T] {
  if n == 0 {
    Nil
  } else {
    match self {
      Empty => Nil
      Cons(x, xs) => Cons(x, xs().take(n - 1))
    }
  }
}
```

使用thunk实现的惰性数据结构简单易用，也很好地解决了上文中的问题。这种方法需要用户明确指出代码的某处应该延迟计算，而惰性语言的策略则要激进地多：它默认对所有用户定义的函数使用延迟计算策略！我们将在下文中展示一种简单的惰性函数式语言的极小实现，并对其背后的理论模型稍做介绍。

## **03 一种惰性求值语言及其抽象语法树**

本文所用的示例是一个刻意弄得跟clojure（这是一种lisp方言）有点像的惰性求值语言（叫做coreF），这样做是因为可以在markdown中使用clojure语言的语法高亮。请别担心，语法可能有点麻烦，但是绝对够简单。

定义函数使用defn关键字：

```clojure
(defn factorial[n] ;; n是参数，此函数计算n的阶乘
  (if (eq n 0) ;; 此处开始到下面三行是它的定义
    1
    (mul n (factorial (sub n 1))))

```

我们在平时叫它函数就好，但当我们讨论惰性函数式语言时，就需要使用一个比较专业的名词：Super Combinator(超组合子)。超组合子的定义中所有的自由变量都应该包含在开头的一对[]里。

虽然Super Combinator直译就是超组合子，但是这个翻译在函数程序设计语言 ：计算模型、编译技术、系统结构等书中已经出现过了。

coreF程序的执行从main开始，调用某个超组合子可以当作用它的定义进行替换。

```clojure
(defn main[] (factorial 42))
```

对于main这种没有参数的超组合子，又另有一个名词来描述它：Constant Applicative Forms（简称CAF）。

coreF还具有一些语言特性（如自定义数据结构和用来解构的case表达式, 用来定义局部变量的let和letrec）， 但本文所需要的只有上面这么多（甚至还没有这么多，因为eq、mul、sub等内置函数之后才会实现）。

coreF没有匿名函数，这是因为匿名函数会引入额外的自由变量。消除它们需要一步额外的转换步骤：lambda lifting。这一技术可以将lambda表达式转换为外部的一个超组合子，但这不是惰性求值的重点，故此处略去。

超组合子最后会被解析为ScDef[String]，但写解析器是件乏味差事，笔者会在给出最终代码时一并提供。

```rust
enum RawExpr[T] {
  Var(T)
  Num(Int)
  Constructor(Int, Int) // tag, arity
  App(RawExpr[T], RawExpr[T])
  Let(Bool, List[(T, RawExpr[T])], RawExpr[T]) // isRec, Defs, Body
  Case(RawExpr[T], List[(Int, List[T], RawExpr[T])])
}

struct ScDef[T] {
  name : String
  args : List[T]
  body : RawExpr[T]
} derive (Show)

```

此外，还有一些预定义的coreF程序需要给出：

```rust
let preludeDefs : List[ScDef[String]] = {
  let id = ScDef::new("I", arglist1("x"), Var("x")) // id x = x
  let k = ScDef::new("K", arglist2("x", "y"), Var("x")) // K x y = x
  let k1 = ScDef::new("K1", arglist2("x", "y"), Var("y")) // K1 x y = y
  let s = ScDef::new("S", arglist3("f", "g", "x"), App(App(Var("f"), Var("x")), App(Var("g"), Var("x")))) // S f g x = f x (g x)
  let compose = ScDef::new("compose", arglist3("f", "g", "x"), App(Var("f"), App(Var("g"), Var("x")))) // compose f g x = f (g x)
  let twice = ScDef::new("twice", arglist1("f"), App(App(Var("compose"), Var("f")), Var("f"))) // twice f = compose f f
  Cons(id, Cons(k, Cons(k1, Cons(s, Cons(compose, Cons(twice, Nil))))))
}

```

## **04 为什么是图**

在coreF语言中，表达式（不是上面的RawExpr[T]，而是运行时的表达式）在求值时以图（graph）而非树的形式存储在内存中。

为什么要这样？看看这个程序：

```clojure
(defn square[x]  (mul x x))
(defn main[] (square (square 3)))
```

如果我们按照一般的树形表达式来求值，表达式会被规约成：

```clojure
(mul (square 3) (square 3))
```

则(square 3)会被重复求值两遍。这绝对不是那些选择惰性求值的人想要的。

为了展示得更清晰一点，我们用MoonBit代码来做个不大恰当的类比。

```clojure
fn square(thunk : () -> Int) -> Int {
  thunk() * thunk()
}
```

用图来表示程序是为了共享计算结果，避免重复计算(要达到这个目的还需要在实现图规约算法时实现为原地更新)。关于原地更新，我们仍然用MoonBit代码模拟一下看看：

```rust
enum LazyData[T] {
  Waiting(() -> T)
  Done(T)
}

struct LazyRef[T] {
  mut data : LazyData[T]
}

fn extract[T](self : LazyRef[T]) -> T {
  match self.data {
    Waiting(thunk) => {
      let value = thunk()
      self.data = Done(value) // 原地更新
      value
    }
    Done(value) => value
  }
}

fn square(x : LazyRef[Int]) -> Int {
  x.extract() * x.extract()
}

```

无论左右两侧哪一边的extract方法先执行，它都会更新引用的可变字段并将内容替换为计算结果。那么第二次执行extract方法就不必再算一遍了。

## **05 一些约定**

接下来我们要讨论的是图规约如何进行。在此之前，需要预先交代一些名词与基本事实。我们仍然可以使用这个程序作为例子：

```clojure
(defn square[x]  (mul x x)) ;; 乘法运算
(defn main[] (square (square 3)))
```

- mul这样的东西是预先定义好的，称作*Built-in primitive*

* 对一个表达式进行求值（当然是惰性的）并对它在图中对应的节点进行原地更新，称为规约。
* (square 3)是一个可规约表达式（reducible expression，一般缩写为redex），由square和它的一个参数组成。它可以被规约为(mul 3 3)。(mul 3 3)也是一个redex，但是它和(square 3)是两种不同的redex（因为square是自定义的超组合子，而mul是实现内置的primitive）。
* (mul 3 3)的规约结果是表达式9，9没办法再进行规约，这种无法继续规约的基础表达式称为Normal form。
* 一个表达式中可能存在多个子表达式(如(mul (add 3 5) (mul 7 9)))，在这种情况下表达式的规约顺序是很重要的—一些程序只在特定的规约顺序下停机。

- 有个特殊的规约顺序永远选择最外层的redex进行规约，这叫做normal order reduction。下文也将统一采用这种规约顺序。

那么，可以用这样的伪代码描述图规约：

```
如果存在可规约表达式 {
    选择最外层的可规约表达式
    规约
    用规约结果更新图
}

```

这还是有些过分抽象了，让我们找几个例子来演示一下如何在纸面上执行规约。

### **第一步：找出下一个redex**

整个程序的执行从main开始：

```clojure
(defn square[x]  (mul x x))
(defn main[] (add 33 (square 3)))
```

main本身是一个CAF - 这是最简单的一种redex，我们执行替换，则当前需要处理的表达式为：

```clojure
(add 33 (square 3))
```

根据找最外层redex的原则，我们似乎马上就找到了add和它的两个参数共同构成的redex（暂且这样认为）。

但是稍等！由于默认柯里化的存在，这个表达式对应的抽象语法树实际上是多个App节点嵌套构成的，大致上是这样（为了方便阅读此处有简化）。

```clojure
App(App(add, 33), square3)
```

这个从add到最外层App节点的链式结构叫做Spine（英文中的"脊柱"）。

回过头来检查一下，add是一个内部定义的primitive, 但由于它的第二个参数(square 3)不是normal form，我们没办法规约它（把一个未求值的表达式和一个整数相加，有点太荒谬了）。所以还不能说我们找到的(add 33 (square 3))是个redex，它只能说是最外层的函数应用罢了，为了规约它，必须先规约(square 3)。

### **第二步：规约**

square是一个用户定义的超组合子，所以对(square 3)进行规约只需要做参数替换即可。

不过，假如某个redex中参数的数量少于该超组合子所需的数量——这种场景常见于高阶函数，举个例子，要让某个列表中的所有整数全部扩大三倍：

```clojure
(map (mul 3) list-of-int)
```

这里的(mul 3)因为参数数量不够所以没法作为redex处理，它是一个weak head normal form（一般缩写为WHNF），在这种情况下即使它的子表达式中包含redex，也不需要做任何事。

### **第三步：更新**

这一步只影响执行效率，纸面推导不做即可。

这些操作在纸面上很好完成（在代码量不超过半张纸的时候），但是当我们把目光转向计算机，具体该怎样把这些步骤转化成可执行的代码呢？

为了解答这个问题，探索惰性求值的程序语言界先驱们提出了多种对惰性求值进行建模的**抽象机器(abstract machine)**，这其中包括：

- G-Machine
- Three Instruction Machine
- ABC Machine(它被Clean语言使用)
- Spineless Tagless G-Machine（缩写为STG, 被今天的Haskell语言使用）

它们是一种用于指导编译器实现的执行模型，需要注意的是，比起今天所流行的各种虚拟机(例如JVM)，抽象机器更像编译器的中间表示(IR)。以Haskell的编译器GHC为例，它在生成STG代码后并不会将它送给一个解释器直接执行，而是根据所选的后端进一步转换为LLVM、C代码或者机器码。

为了简化实现，本文将直接用MoonBit语言编写一个G-Machine指令的解释器，从一个极小化的例子开始一步步地加入更多特性。

## **06 G-Machine概览**

G-Machine虽然是惰性函数式语言的抽象机器，但是它的结构和编写一般命令式语言所需接触的概念差异并不算太大，它也有堆、栈这种结构，并且其指令按顺序执行。不同之处大概有这些：

- 堆内存的基本单位不是字节，而是图节点。
- 栈里只放指向堆的地址，不放实际数据。

> 这样的设计并不实用，但是比较简单

coreF里的超组合子会被编译成一系列G-Machine指令，大致可以分为这几种：

- 访问数据的指令，例如PushArg（访问参数用），PushGlobal（访问其他超组合子用）
- 在堆上构建/更新图节点的指令，如MkApp、PushInt、Update
- 清理栈内无用地址的Pop指令
- 表达控制流的Unwind指令

## **07 解剖G-Machine状态**

目前这个简单版本G-Machine的状态包括：

- 堆(Heap)，这是存放表达式图和超组合子对应指令序列的地方。

```rust
type Addr Int derive(Eq, Show) // 使用type关键字包装一个地址类型

enum Node { // 图节点用一个枚举类型描述
  NNum(Int)
  NApp(Addr, Addr) // 应用节点
  NGlobal(String, Int, List[Instruction]) // 存放超组合子的参数数量和对应指令序列
  NInd(Addr) // Indirection节点, 实现惰性求值的关键一环
} derive (Eq)

struct GHeap { // 堆使用数组，数组中内容为None的空间是可使用的空闲内存
  mut objectCount : Int
  memory : Array[Option[Node]]
}

// 给节点分配堆空间
fn alloc(self : GHeap, node : Node) -> Addr {
  let heap = self
  // 假设堆中还有空余位置
  fn next(n : Int) -> Int {
    (n + 1) % heap.memory.length()
  }
  fn free(i : Int) -> Bool {
    match heap.memory[i] {
      None => true
      _    => false
    }
  }
  let mut i = heap.objectCount
  while not(free(i)) {
    i = next(i)
  }
  heap.memory[i] = Some(node)
  return Addr(i)
}

```

- 栈，栈内只存放指向堆的地址。简单的实现用List[Addr]即可
- 全局表，它是一个记录着超组合子名字（包括预定义的和用户定义的）和对应NGlobal节点地址的映射表。笔者选择用RobinHood哈希表实现。
- 当前所需执行的代码序列
- 执行状况统计数据，比较简单的实现是计算执行了多少条指令。

```rust
type GStats Int

let statInitial : GStats = GStats(0)

fn statInc(self : GStats) -> GStats {
  let GStats(n) = self
  GStats(n + 1)
}

fn statGet(self : GStats) -> Int {
  let GStats(n) = self
  return n
}

```

整个状态使用类型GState表示：

```rust
struct GState {
  mut stack : List[Addr]
  heap : GHeap
  globals : RHTable[String, Addr]
  mut code : List[Instruction]
  mut stats : GStats
}

fn putStack(self : GState, addr : Addr) {
  self.stack = Cons(addr, self.stack)
}

fn putCode(self : GState, is : List[Instruction]) {
  self.code = append(is, self.code)
}

fn pop1(self : GState) -> Addr {
  match self.stack {
    Cons(addr, reststack) => {
      self.stack = reststack
      addr
    }
    Nil => {
      abort("pop1: stack size smaller than 1")
    }
  }
}

fn pop2(self : GState) -> (Addr, Addr) {
  // 弹出栈顶两个元素
  // 返回(第一个， 第二个)
  match self.stack {
    Cons(addr1, Cons(addr2, reststack)) => {
      self.stack = reststack
      (addr1, addr2)
    }
    otherwise => {
      abort("pop2: stack size smaller than 2")
    }
  }
}

```

现在我们可以回顾前文中在纸面上推导的图规约算法一一对应到这台抽象机器了：

- 机器的初始状态下，所有编译好的超组合子都已经被放到堆上的NGlobal节点中，而此时G-Machine中的当前代码序列只包含两条指令，第一条将main的对应节点地址放到栈上，第二条将main的对应指令序列加载到当前指令序列。
- main的对应指令序列会在堆上分配节点并装入相应数据，最后在堆内存中构造出一个图，这个过程称为main的"实例化"。构造完毕后这个图的入口地址会被放到栈顶。
- 完成实例化之后需要做收尾工作，即更新图节点(由于main没有参数，所以不必清理栈中的残留无用地址)并寻找下一个redex。

这些工作都有对应的指令实现。

## **08 各指令作用**

目前这个极度简化的G-Machine共有7条指令：

```rust
enum Instruction {
  Unwind
  PushGlobal(String)
  PushInt(Int)
  PushArg(Int)
  MkApp
  Update(Int)
  Pop(Int)
} derive (Eq, Debug, Show)

```

PushInt指令最为简单，它在堆上分配一个NNum节点，并将它的地址入栈。

```rust
fn pushint(self : GState, num : Int) {
  let addr = self.heap.alloc(NNum(num))
  self.putStack(addr)
}
```

PushGlobal指令从全局表中找到指定超组合子的地址，然后将地址入栈。

```rust
fn pushglobal(self : GState, name : String) {
  let sc = self.globals[name]
  match sc {
    None => abort("pushglobal(): cant find supercombinator \(name)")
    Some(addr) => {
      self.putStack(addr)
    }
  }
}
```

PushArg则复杂一些，它对栈内的地址布局有特定要求：第一个地址应该指向超组合子节点，紧随其后的n个地址则指向N个NApp节点。而PushArg会取到第offset + 1个参数。

```rust
fn pusharg(self : GState, offset : Int) {
  // 跳过首个超组合子节点
  // 访问第offset + 1个NApp节点
  let appaddr = nth(self.stack, offset + 1)
  let arg = match self.heap[appaddr] {
    NApp(_, arg) => arg
    otherwise => abort("pusharg: stack offset \(offset) address \(appaddr) node \(otherwise), not a applicative node")
  }
  self.putStack(arg)
}
```

MkApp指令从栈顶取出两个地址，然后构造一个NApp节点并将地址入栈。

```rust
fn mkapp(self : GState) {
  let (a1, a2) = self.pop2()
  let appaddr = self.heap.alloc(NApp(a1, a2))
  self.putStack(appaddr)
}
```

Update指令假设栈内第一个地址指向当前redex求值结果，跳过紧随其后的超组合子节点地址，把第N个NApp节点替换为一个指向求值结果的间接节点。如果当前redex是CAF，那就直接把它在堆上的NGlobal节点替换掉. 从这里也能看出来，为什么在惰性函数式语言里无参数函数和普通变量没有太多区别。

```rust
fn update(self : GState, n : Int) {
  let addr = self.pop1()
  let dst = nth(self.stack, n)
  self.heap[dst] = NInd(addr)
}
```

Unwind指令是G-Machine中类似于求值循环一样的东西，它有好几个分支条件，根据栈顶地址对应节点的种类进行判断

- Nnum，什么也不做
- NApp，将左侧地址入栈，再次Unwind
- NGlobal，在栈内有足够参数的情况下，将该超组合子加载到当前代码
- NInd，将该间接节点内地址入栈，再次Unwind

```rust
fn unwind(self : GState) {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(_) => self.putStack(addr)
    NApp(a1, _) => {
      self.putStack(addr)
      self.putStack(a1)
      self.putCode(Cons(Unwind, Nil))
    }
    NGlobal(_, n, c) => {
      if length(self.stack) < n {
        abort("Unwinding with too few arguments")
      } else {
        self.putStack(addr)
        self.putCode(c)
      }
    }
    NInd(a) => {
      self.putStack(a)
      self.putCode(Cons(Unwind, Nil))
    }
    otherwise => abort("unwind() : wrong kind of node \(otherwise), address \(addr)")
  }
}
```

`Pop`指令弹出n个地址，就不用函数单独实现了。

## **09 将超组合子编译为指令序列**

在G-Machine概览一节，我们大致描述了一下编译后的超组合子具有何种行为，现在可以精确地描述超组合子的编译了。

首先，在一个超组合子编译出的指令序列执行前，栈内一定已经存在这样一些地址：

- 最顶部的地址指向一个NGlobal节点(超组合子本身)
- 紧随其后的N个地址（N是该超组合子的参数数量）则指向一系列的App节点 - 正好对应到一个redex的spine，栈最底层的地址指向表达式最外层的App节点，其余以此类推。

在编译超组合子时，我们需要维护一个环境，这个环境允许我们在编译过程中通过参数的名字找到参数在栈中的相对位置。此外，由于完成超组合子的实例化之后需要清理掉前面的N+1个地址，还需要传入参数的个数N。

> 此处所说的“参数”都是指向堆上App节点的地址，通过pusharg指令可以访问到真正的参数地址

```rust
fn compileSC(self : ScDef[String]) -> (String, Int, List[Instruction]) {
  let name = self.name
  let body = self.body
  let mut arity = 0
  fn gen_env(i : Int, args : List[String]) -> List[(String, Int)] {
    match args {
      Nil => {
        arity = i
        return Nil
      }
      Cons(s, ss) => Cons((s, i), gen_env(i + 1, ss))
    }
  }
  let env = gen_env(0, self.args)
  (name, arity, compileR(body, env, arity))
}
```

compileR函数通过调用compileC函数来生成对超组合子进行实例化的代码，并在后面加上三条指令。这三条指令各自的工作是：

- Update(N)将堆中原本的redex更新为一个NInd节点，这个间接节点则指向刚刚实例化出来的超组合子
- Pop(N)清理栈中已经无用的地址
- Unwind寻找redex开始下一次规约

```rust
fn compileR(self : RawExpr[String], env : List[(String, Int)], arity : Int) -> List[Instruction] {
  if arity == 0 {
    // 指令Pop 0实际上什么也没做，故 arity == 0 时不生成
    append(compileC(self, env), from_array([Update(arity), Unwind]))
  } else {
    append(compileC(self, env), from_array([Update(arity), Pop(arity), Unwind]))
  }
}

```

在编译超组合子的定义时使用比较粗糙的方式：一个变量如果不是参数，就当成其他超组合子（写错了会导致运行时错误）。对于函数应用，先编译右侧表达式，然后将环境中所有参数对应的偏移量加一（因为栈顶多出了一个地址指向实例化之后的右侧表达式），再编译左侧，最后加上MkApp指令。

```rust
fn compileC(self : RawExpr[String], env : List[(String, Int)]) -> List[Instruction] {
  match self {
    Var(s) => {
      match lookupENV(env, s) {
        None => from_array([PushGlobal(s)])
        Some(n) => from_array([PushArg(n)])
      }
    }
    Num(n) => from_array([PushInt(n)])
    App(e1, e2) => {
      append(compileC(e2, env), append(compileC(e1, argOffset(1, env)), from_array([MkApp])))
    }
    _ => abort("not support yet")
  }
}

```

## **10 运行G-Machine**

编译完毕的超组合子还需要放到堆上（以及把地址放到全局表里），递归处理即可。

```rust
fn buildInitialHeap(scdefs : List[(String, Int, List[Instruction])]) -> (GHeap, RHTable[String, Addr]) {
  let heap = { objectCount : 0, memory : Array::make(10000, None) }
  let globals = RHTable::new(50)
  fn go(lst : List[(String, Int, List[Instruction])]) {
    match lst {
      Nil => ()
      Cons((name, arity, instrs), rest) => {
        let addr = heap.alloc(NGlobal(name, arity, instrs))
        globals[name] = addr
        go(rest)
      }
    }
  }
  go(scdefs)
  return (heap, globals)
}

```

定义函数step，它将G-Machine的状态更新一步，如果已经到达最终状态就返回false。

```rust
fn step(self : GState) -> Bool {
  match self.code {
    Nil => { return false }
    Cons(i, is) => {
      self.code = is
      self.statInc()
      match i {
        PushGlobal(f) => self.pushglobal(f)
        PushInt(n) => self.pushint(n)
        PushArg(n) => self.pusharg(n)
        MkApp => self.mkapp()
        Unwind => self.unwind()
        Update(n) => self.update(n)
        Pop(n) => { self.stack = drop(self.stack, n) } // 比较简单就不用额外的函数实现了
      }
      return true
    }
  }
}

```

另外定义函数reify不断执行step直到最终状态：

```rust
fn reify(self : GState) {
  if self.step() {
    self.reify()
  } else {
    let stack = self.stack
    match stack {
      Cons(addr, Nil) => {
        let res = self.heap[addr]
        println("\(res)")
      }
      _ => abort("wrong stack \(stack)")
    }
  }
}

```

对上文中的各部分进行组装：

```rust
fn run(codes : List[String]) {
  fn parse_then_compile(code : String) -> (String, Int, List[Instruction]) {
    let code = TokenStream::new(code)
    let code = parseSC(code)
    let code = compileSC(code)
    return code
  }
  let codes = append(map(parse_then_compile, codes), map(compileSC, preludeDefs))
  let (heap, globals) = buildInitialHeap(codes)
  let initialState : GState = {
    heap : heap,
    stack : Nil,
    code : initialCode,
    globals : globals,
    stats : initialStat
  }
  initialState.reify()
}

```

## **尾声**

我们现在所构建的G-Machine特性过少，很难运行稍微像样的程序。在下一篇文中，我们将一步步加入primitive和自定义数据结构等特性，并在结尾介绍G-Machine之后的惰性求值技术。

本文参考：Simon L Peyton Jones 所写的 _Implementing Functional Languages: a tutorial_
