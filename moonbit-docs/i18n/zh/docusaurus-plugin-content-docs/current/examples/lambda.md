# 无类型 Lambda 演算

相信点开这篇文章的您或多或少地听说过函数式编程这个名词。在摩尔定律失效的今天，对多核处理器的充分利用成为了一种越发重要的程序优化方法，而函数式编程也因为其并行运算亲和的特点在大众视野中越发频繁地出现。究其原因，离不开它从其理论上的祖先之一 - lambda演算那里所继承的特征。
而lambda演算这一起源于20世纪30年代，出自图灵导师阿隆佐·邱奇之手的形式系统如今已经发展成了蔚为大观的一个大家族，本文将展示其中最基础的一种：无类型lambda演算(这也是最早阿隆佐·邱奇提出的那种)

## 无类型lambda演算的基本规则

无类型lambda演算中能做的事情只有定义lambda(经常称为Abstraction)和调用lambda(经常称为Application)，它们也是lambda演算中的基础表达式。

由于函数式编程范式对主流编程语言的影响，大多数程序员对lambda表达式这个名字已经不会感到陌生了，不过，无类型lambda演算中的lambda要比主流编程语言简单一些。一个lambda通常看起来就像这样：`λx.x x`, 其中x是它的参数(每个lambda只能有一个参数)，`.`是分隔参数与表达式具体定义的分隔符，后面的`x x`便是它的定义了。

> 也有些材料的记法不写空格，上面的例子要改写成`λx.xx`

上面的`x x`如果换成`x(x)`, 可能更符合我们在一般语言中见到的函数调用。但在lambda演算较常见的写法中，调用一个lambda只需要在它和它的参数中间写个空格。此处我们调用`x`所给出的参数就是`x`自己。

以上两种表达式和定义lambda时引入的变量加在一起合称lambda项，我们在MoonBit里用一个enum类型来表示它

```rust
enum Term {
  Var(String) // 变量
  Abs(String, Term) // 定义lambda，变量用字符串表示
  App(Term, Term) // 调用lambda
}
```

我们在日常编程中所接触的概念诸如布尔值，if表达式，自然数算术乃至递归都可以通过lambda表达式实现，但这并非本文内容的重心所在，有兴趣的读者可以参阅[Programming with Nothing](https://segmentfault.com/a/1190000000497092)这篇博客。

要实现一个无类型lambda演算的解释器，我们所需要了解的基本就只有两条规则：Alpha转换与Beta规约

Alpha转换所描述的事实是，lambda的结构是重点，变量名叫什么没那么重要。`λx.x`和`λfoo.foo`可以互相替换。对于某些有重复变量名的嵌套lambda例如`λx.(λx.x) x`，重命名时不能把内层的变量也重命名了，例如上面的例子可以通过Alpha转换写成`λy.(λx.x) y`.

Beta规约则专注于处理lambda的调用，还是举一个例子

```
(λx.(λy.x)) (λs.(λz.z))
```

在无类型lambda演算中，调用lambda之后所需要作的事情仅仅是对参数进行替换(substitution)，上面这个例子里就需要把变量`x`替换成`(λs.(λz.z))`，得到的结果是

```
(λy.(λs.(λz.z)))
```

想看更多的例子可以参见这篇文章：https://zhuanlan.zhihu.com/p/57972301

## 自由变量与变量捕获

一个lambda项中的变量如果在它所处的上下文中没有定义，那么我们叫它自由变量。例如`(λx.(λy.fgv h))`这个lambda项中变量`fgv`和`h`就没有对应的lambda定义.

在进行Beta规约时，如果用于替换变量的那个lambda项中含有自由变量，可能会导致一种被称为"变量捕获"的行为

```
(λx.(λy.x)) (λz.y)
```

上面这个表达式在替换后会变成

```
λy.λz.y
```

`λz.y`中的自由变量被当成了某个lambda的参数，这显然不是我们想要的。

变量捕获问题在编写解释器时的常见解决方案是在替换前遍历表达式得到一个自由变量的集合, 做替换时遇到内层lambda就判断一下变量名在不在这个自由变量集合里面

```rust
// (λx.E) T => E.subst(x, T)
fn subst(self : Term, var : String, term : Term) -> Term {
  let freeVars : Set[String] = term.get_free_vars()
  match self {
    Abs(variable, body) => {
      if freeVars.contains(variable) {
        //自由变量集合中有当前这个内层lambda的参数名，即会发生变量捕获
        abort("subst(): error while encountering \(variable)")
      } else {
        ......
      }
    }
    ......
  }
}
```

此处我们介绍一种较少见但具有一定便利性的方法：de bruijn index。

## de bruijn index

de bruijn index(德布朗指数)是一种用整数表示lambda项中变量的技术，具体地说，它用变量所在位置和原先引入它的位置中间有几层lambda来替换特定变量。

```
λx.(λy.x (λz.z z))

λ.(λ.1 (λ.0 0))
```

上面的例子中，变量`x`和引入它的地方`λx`中间有一个`λy`, 于是将`x`替换为`1`，而`z`和定义它的位置中间没有夹杂其他的lambda，于是直接用`0`替换。某种程度上说，德布朗指数的值描述的是变量与对应lambda的相对距离，此处的距离衡量标注就是中间嵌套的lambda层数。

> 同一个变量在不同的地方可能会用不同的整数来替换

我们定义一个新类型`TermDBI`来表示使用德布朗指数的lambda项

```rust
enum TermDBI {
  VarDBI(String, Int)
  AbsDBI(String, TermDBI)
  AppDBI(TermDBI, TermDBI)
}
```

不过直接编写以及阅读德布朗指数形式的lambda很痛苦，所以我们需要编写一个将`Term`转换成`TermDBI`的函数`debruijn()` - 这也是`TermDBI`类型定义中仍有`String`的原因，保留原变量名可用于它的`to_string`方法，这样就可以方便地用`println`打印求值结果查看了。

```rust
fn to_string(self : TermDBI) -> String {
  match self {
    VarDBI(name, _) => name
    AbsDBI(name, body) => "(\\\(name).\(body))"
    AppDBI(t1, t2) => "\(t1) \(t2)"
  }
}
```

为了简化实现，如果输入的Term中含有自由变量，`debruijn()`函数会直接报错。MoonBit中一般用`Result[V, E]`类型表示可能会出错的计算, 它有`Ok(V)`和`Err(E)`两个值构造子，分别代表计算成功与失败。

> 使用过Rust语言的读者应该会感到熟悉

```rust
fn bruijn(self : Term) -> Result[TermDBI, String]
```

我们采取一种笨办法来保存变量名与相关联的嵌套深度，首先定义`Index`类型

```rust
struct Index {
  name : String
  depth : Int
}
```

然后写一个从`List[Index]`中根据特定`name`查找对应`depth`的辅助函数

```rust
// 查找环境中第一个varname对应的整数
fn find(m : List[Index], varname : String) -> Result[Int, String] {
  match m {
    Nil => Err(varname) // abort("variable \'\(varname)\' not found")
    Cons(i, rest) => {
      if i.name == varname {
        Ok(i.depth)
      } else {
        find(rest, varname)
      }
    }
  }
}
```

现在可以补全`debruijn()`函数了。

- `Var`的处理最简单，只需要查表寻找对应`depth`即可。

- `Abs`稍微复杂一点，首先对列表中所有`index`的`depth`加一(因为lambda嵌套加深了一层)，然后在列表的开头加上`{ name : varname, depth : 0 }`

+`App`在两个子项都能转换时成功，否则返回一个`Err`

```rust
  fn go(m : List[Index], t : Term) -> Result[TermDBI, String] {
    match t {
      Var(name) => {
        let idx = find(m, name)?
        Ok(Var(name, idx))
      }
      Abs(varname, body) => {
        let m = m.map(fn (index){
          { name : index.name, depth : index.depth + 1 }
        })
        let m = List::Cons({ name : varname, depth : 0 }, m)
        let term = go(m, body)?
        Ok(Abs(varname, term))
      }
      App(e1, e2) => {
        let e1 = go(m, e1)?
        let e2 = go(m, e2)?
        Ok(App(e1, e2))
      }
    }
  }
  go(Nil, self)
```

## 在`TermDBI`上做规约

规约主要处理的是`App`，即调用

```rust
fn eval(self : TermDBI) -> TermDBI {
  match self {
    AppDBI(t1, t2) => {
      match (eval(t1), eval(t2)) {
        (AbsDBI(_, t1), t2) => eval(subst(t1, t2))
        (t1, t2) => AppDBI(t1, t2)
      }
    }
    AbsDBI(_) => self
    otherwise => abort("eval(): \(otherwise) ")
    // eval应该不会遇到自由变量才对
  }
}
```

首先对两个子项尝试规约，然后看`eval(t1)`得到的是否是一个lambda，如果是，就执行一步变量替换(通过subst函数)然后继续化简。对于lambda(即`Abs`), 直接原样返回即可。

subst函数的实现在不用考虑自由变量的情况下简单了许多, 只要记录递归到当前位置的深度并且与遇到的变量进行比对，大小相等就是需要替换的目标变量。

```rust
fn subst(t1 : TermDBI, t2 : TermDBI) -> TermDBI {
  fn go(t1 : TermDBI, t2 : TermDBI, depth : Int) -> TermDBI {
    match t1 {
      VarDBI(name, d) => {
        if d == depth {
          t2
        } else {
          t1
        }
      }
      AbsDBI(name, t) => {
        AbsDBI(name, go(t, t2, depth + 1))
      }
      AppDBI(tl, tr) => {
        AppDBI(go(tl, t2, depth), go(tr, t2, depth))
      }
    }
  }
  go(t1, t2, 0)
}
```

完整实现代码于此：try.moonbitlang.cn/#a59bfd2e

## 改进

笔者在保存变量名到索引的对应关系时使用了`List[Index]`类型，并且在每增加一层lambda时更新整个列表，但是这其实是个很笨的办法。相信聪明且注意力集中的读者很快就能发现，其实只需要保存一个`List[String]`就够了，有兴趣的读者可以自己试着做一做。
