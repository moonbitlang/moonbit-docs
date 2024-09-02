# 实现 Haskell 求值语义（系列三）

本期文章为在MoonBit中实现惰性求值的第三篇。在上一篇中，我们了解了let表达式的编译方法以及如何实现基本的算术比较操作。这一篇文章中，我们将实现一种基于上下文的优化方法，并添加对数据结构的支持。

## 追踪上下文

回顾一下我们之前实现primitive的方法：

```rust
let compiledPrimitives : List[(String, Int, List[Instruction])] = List::[
  // 算术
  ("add", 2, List::[Push(1), Eval, Push(1), Eval, Add, Update(2), Pop(2), Unwind]),
  ("sub", 2, List::[Push(1), Eval, Push(1), Eval, Sub, Update(2), Pop(2), Unwind]),
  ("mul", 2, List::[Push(1), Eval, Push(1), Eval, Mul, Update(2), Pop(2), Unwind]),
  ("div", 2, List::[Push(1), Eval, Push(1), Eval, Div, Update(2), Pop(2), Unwind]),
  // 比较
  ("eq",  2, List::[Push(1), Eval, Push(1), Eval, Eq,  Update(2), Pop(2), Unwind]),
  ("neq", 2, List::[Push(1), Eval, Push(1), Eval, Ne,  Update(2), Pop(2), Unwind]),
  ("ge",  2, List::[Push(1), Eval, Push(1), Eval, Ge,  Update(2), Pop(2), Unwind]),
  ("gt",  2, List::[Push(1), Eval, Push(1), Eval, Gt,  Update(2), Pop(2), Unwind]),
  ("le",  2, List::[Push(1), Eval, Push(1), Eval, Le,  Update(2), Pop(2), Unwind]),
  ("lt",  2, List::[Push(1), Eval, Push(1), Eval, Lt,  Update(2), Pop(2), Unwind]),
  // 杂项
  ("negate", 1, List::[Push(0), Eval, Neg, Update(1), Pop(1), Unwind]),
  ("if",     3,  List::[Push(0), Eval, Cond(List::[Push(1)], List::[Push(2)]), Update(3), Pop(3), Unwind])
]
```

这样的实现引入了很多`Eval`指令，但它们未必总是用得上。例如：

```clojure
(add 3 (mul 4 5))
```

`add`的两个参数在执行`Eval`之前就已经是WHNF, 这里的`Eval`指令是多余的。

一种可行的优化方法是在编译表达式时注意其上下文。例如，add需要它的参数被求值成WHNF，那么它的参数在编译时就处于严格(Strict)上下文中。通过这种方式，我们可以识别出一部分可以安全地按照严格求值进行编译的表达式(仅有一部分)

- 一个超组合子定义中的表达式处于严格上下文中

- 如果`(op e1 e2)`处于严格上下文中(此处`op`是一个primitive)，那么`e1`和`e2`也处于严格上下文中

- 如果`(let (.....) e)`处于严格上下文中，那么`e`也处于严格上下文中(但是前面的局部变量对应的表达式就不是，因为e不一定需要它们的结果)

我们用函数`compileE`实现这种严格求值上下文下的编译，它所生成的指令可以保证*栈顶地址指向的值一定是一个WHNF*。

首先对于默认分支，我们仅仅在`compileC`的结果后面加一条`Eval`指令

```rust
append(compileC(self, env), List::[Eval])
```

常数则直接push

```rust
Num(n) => List::[PushInt(n)]
```

对于`let/letrec`表达式，之前特意设计的`compileLet`和`compileLetrec`便起到用处了，编译一个严格上下文中的`let/letrec`表达式只需要用`compileE`编译其主表达式即可

```rust
Let(rec, defs, e) => {
  if rec {
    compileLetrec(compileE, defs, e, env)
  } else {
    compileLet(compileE, defs, e, env)
  }
}
```

`if`和`negate`的参数数量分别为3、1， 需要单独处理。

```rust
App(App(App(Var("if"), b), e1), e2) => {
  let condition = compileE(b, env)
  let branch1 = compileE(e1, env)
  let branch2 = compileE(e2, env)
  append(condition, List::[Cond(branch1, branch2)])
}
App(Var("negate"), e) => {
  append(compileE(e, env), List::[Neg])
}
```

基础的二元运算则可以通过查表统一处理, 首先构建一个叫做`builtinOpS`的哈希表，它允许我们通过primitive的名字查询对应指令。

```rust
let builtinOpS : RHTable[String, Instruction] = {
  let table : RHTable[String, Instruction] = RHTable::new(50)
  table["add"] = Add
  table["mul"] = Mul
  table["sub"] = Sub
  table["div"] = Div
  table["eq"]  = Eq
  table["neq"] = Ne
  table["ge"] = Ge
  table["gt"] = Gt
  table["le"] = Le
  table["lt"] = Lt
  table
}
```

其余处理则没有太多区别。

```rust
App(App(Var(op), e0), e1) => {
  match builtinOpS[op] {
    None => append(compileC(self, env), List::[Eval]) // 不是primitive op, 走默认分支
    Some(instr) => {
      let code1 = compileE(e1, env)
      let code0 = compileE(e0, argOffset(1, env))
      append(code1, append(code0, List::[instr]))
    }
  }
}
```

大功告成了吗？好像是的，不过，除了整数，其实还有另外一种WHNF: 偏应用(partial application)的函数

所谓偏应用，就是指参数数量不足。这种情况常见于高阶函数，例如

```clojure
(map (add 1) listofnumbers)
```

这里的`(add 1)`就是一个偏应用.

要让新的编译策略产生的代码不出问题，我们还得修改`Unwind`指令关于`NGlobal`分支的实现。在参数数量不足且dump中有保存的栈时，只保留原本的redex并且还原栈。

```rust
NGlobal(_, n, c) => {
  let k = length(self.stack)
  if k < n {
    match self.dump {
      Nil => abort("Unwinding with too few arguments")
      Cons((i, s), rest) => {
        // a1 : ...... : ak
        // ||
        // ak : s
        // 保留redex, 还原栈
        self.stack = append(drop(self.stack, k - 1), s)
        self.dump = rest
        self.code = i
      }
    }
  } else {
    ......
  }
}
```

这种基于上下文的严格性分析技术很有用，但是碰上超组合子调用就什么都做不了了。在此处我们简单介绍一下一种基于布尔运算的严格性分析，它可以分析出对于某个超组合子的调用，哪些参数应该使用严格模式编译。

我们首先定义一个概念：bottom，它是一个概念上代表永不停机/异常的值。对于超组合子`f a[1] ...... a[n]`, 如果有一个参数`a[i]`满足`a[i] = bottom`则`f a[1] .... a[i] .... a[n] = bottom`(其他参数都不是bottom)，那说明无论`f`的内部控制流如何复杂，想调用它得到结果**一定**是需要参数`a[i]`的，它应该严格求值。

> 不符合这个条件也不一定是完全不需要，可能只在某个分支中使用了，具体用不用要运行时决定。这种参数是典型的应该惰性求值的例子。

让我们把bottom看作`false`, 非bottom的值看做`true`, 这样一来所有coref中的函数都可以看做布尔函数了。以`abs`为例

```clojure
(defn abs[n]
  (if (lt n 0) (negate n) n))
```

我们自顶向下地分析应该怎么翻译成布尔函数

- 对于`(if x y z)`而言，`x`是一定需要计算的，但`y`和`z`只需要计算一个，那么它被翻译成`x and (y or z)`。以上面这个函数为例说明，如果`n`是bottom, 那么条件`(lt n 0)`也是bottom，则整个表达式的结果也是bottom。
- 对于primitive直接全用and就好

那么判断一个参数是否需要严格地编译，只需要把上面的条件翻译成布尔函数版：`a[i] = false`则`f a[1] .... a[i] .... a[n] = false`(其他参数都是true)。

> 这其实是一种叫做"抽象解释"的程序分析方法

## 自定义数据结构

haskell中的数据结构类型定义与MoonBit的enum相仿，不过，由于CoreF是个用于演示惰性求值的简单玩具语言，它不能自定义数据类型，内置的数据结构只有惰性列表。

```clojure
(defn take[n l]
  (case l
    [(Nil) Nil]
    [(Cons x xs)
      (if (le n 0)
        Nil
        (Cons x (take (sub n 1) xs)))]))
```

如上，通过case表达式可以对列表进行简单的模式匹配。

列表对应的图节点是`NConstr(Int, List[Addr])`, 它由两个部分组成：

- 用于标记不同值构造子的标签，Nil对应的标签是0，Cons对应的标签是1

- 用于存放子结构地址的列表，它的长度对应一个值构造子的参数数量(arity)

> 这个图节点的结构可以用来实现各种数据结构，但是coreF没做类型系统，为了演示方便只实现了惰性列表

我们需要增加两条指令Split和Pack，分别用于拆开列表和组装列表。

```rust
fn split(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NConstr(_, addrs) => {
      // n == addrs.length()
      self.stack = addrs + self.stack
    }
  }
}

fn pack(self : GState, t : Int, n : Int) -> Unit {
  let addrs = self.stack.take(n)
  // 此处假设参数数量一定足够
  self.stack = self.stack.drop(n)
  let addr = self.heap.alloc(NConstr(t, addrs))
  self.putStack(addr)
}
```

此外还需要一条指令`CaseJump`, 实现case表达式

```rust
fn casejump(self : GState, table : List[(Int, List[Instruction])]) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NConstr(t, addrs) => {
      match lookupENV(table, t) {
        None => abort("casejump")
        Some(instrs) => {
          self.code = instrs + self.code
          self.putStack(addr)
        }
      }
    }
    otherwise => abort("casejump(): addr = \{addr} node = \{otherwise}")
  }
}
```

在添加了以上指令后，还需修改`compileC`和`compileE`函数。case表达式需要所匹配的对象已经被求值到WHNF，所以只有compileE函数能编译它。

```rust
// compileE
  Case(e, alts) => {
    compileE(e, env) + List::[CaseJump(compileAlts(alts, env))]
  }
  Constructor(0, 0) => {
    // Nil
    List::[Pack(0, 0)]
  }
  App(App(Constructor(1, 2), x), xs) => {
    // Cons(x, xs)
    compileC(xs, env) + compileC(x, argOffset(1, env)) + List::[Pack(1, 2)]
  }

// compileC
  App(App(Constructor(1, 2), x), xs) => {
    // Cons(x, xs)
    compileC(xs, env) + compileC(x, argOffset(1, env)) + List::[Pack(1, 2)]
  }
  Constructor(0, 0) => {
    // Nil
    List::[Pack(0, 0)]
  }
```

不过，此时有一个问题出现了，先前打印程序求值结果只需要处理简单的`NNum`节点，而`NConstr`节点是有子结构的，并且在列表本身被求值到WHNF时，列表的子结构多半还是待求值的`NApp`节点。我们需要增加一个`Print`指令，它会递归地进行求值并将结果写入`GState`的`output`组件中。

```rust
struct GState {
  output : Buffer
  ......
}

fn gprint(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(n) => {
      self.output.write_string(n.to_string())
      self.output.write_char(' ')
    }
    NConstr(0, Nil) => self.output.write_string("Nil")
    NConstr(1, Cons(addr1, Cons(addr2, Nil))) => {
      // 需要强制对addr1和addr2进行求值，故先执行Eval指令
      self.code = List::[Instruction::Eval, Print, Eval, Print] + self.code
      self.putStack(addr2)
      self.putStack(addr1)
    }
  }
}
```

最后将G-Machine的初始代码改成

```rust
let initialCode : List[Instruction] = List::[PushGlobal("main"), Eval, Print]
```

现在我们可以使用惰性列表编写一些经典的函数式程序,例如基于无穷流的fibonacci数列

```clojure
(defn fibs[] (Cons 0 (Cons 1 (zipWith add fibs (tail fibs)))))
```

在引入数据结构之后，严格性分析也会变得更复杂。以惰性列表为例，关于它有多种求值模式

- 完全严格(要求列表有限并且所有元素都不是bottom)
- 完全惰性
- 头严格(列表可以无限，但是里面的元素不可以有bottom)
- 尾严格(列表必须有限，但是里面的元素可以有bottom)

甚至函数所处的上下文也会改变它对某个参数的求值模式(不能孤立地分析，需要跨函数)，这种较为复杂的严格性分析一般采用射影分析(Projection Analysis)技术，相关文献：

- Projections for Strictness Analysis

- Static Analysis and Code Optimizations in Glasgow Haskell Compiler

- Implementing Projection-based Strictness Analysis

- Theory and Practice of Demand Analysis in Haskell

## 尾声

惰性求值这一技术可以减少运行时的重复运算，与此同时它也引入了一些新的问题。这些问题包括：

- 臭名昭著的副作用顺序问题。

- 冗余节点过多。一些根本不会共享的计算也要把结果放到堆上，这对于利用CPU的缓存机制是不利的。

惰性求值语言的代表haskell对于副作用顺序给出了一个毁誉参半的解决方案：Monad。该方案对急切求值的语言也有一定价值，但网络上关于它的教程往往在介绍此概念时过分强调其数学背景，对如何使用反而疏于讲解。笔者建议不必在这方面花费过多时间。

haskell的后继者Idris2(它已经不是一个惰性的语言了)除了保留Monad，还引入了另一种副作用处理机制：Algebraic Effect。

SPJ设计的Spineless G-Machine改进了冗余节点过多的问题，而作为其后继的STG统一了不同种类节点的数据布局。

除了抽象机器模型上的改进，GHC对haskell程序的优化还重度依赖于基于inline的优化和以射影分析为代表的严格性分析技术。

2004年，GHC的几位设计者发现以前这种参数入栈然后进入某个函数的调用模型(push enter)反而不如将责任交给调用者的eval apply模型，他们发表了一篇论文Making a Fast Curry: Push/Enter vs. Eval/Apply for Higher-order Languages。

2007年，Simon Marlow发现tagless设计中的跳转并执行代码对现代CPU的分支预测器性能影响很大。论文`Faster laziness using dynamic pointer tagging`中描述了几种解决方案。

惰性纯函数式语言展现出了很多别样的可能性，但对它的批评和反思也不少。不过，至少它是一种很有意思的技术！
