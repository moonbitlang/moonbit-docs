# 在 MoonBit 实现线段树(二)

## 引言

在上一篇文章当中我们讨论了最基础线段树的实现，但那棵线段树只能做到区间的查询（当然单点的修改与查询也是可以的），但做不到区间的修改（一个经典的应用是区间加法，即整个区间都加上某个值）。

在本节当中我们将基于上次的线段树继续加深抽象，引入 LazyTag 的概念来解决区间修改的问题，完成一棵功能基本完备的线段树。

## 怎么做到区间修改？

先设想如果我们在线段树上给一个区间都加上某个数会发生什么？或者换种说法，以最简单的办法来说，我们是如何完成它的？

![1](./1.svg)

以上节课的线段树为例，上面这张图中，我们对 [4, 7] 的区间都加上 1。这时候我们会发现这需要把涉及到这段区间的所有树上部分都重新构建维护一次，这个时间代价我们肯定是不能接受的。

那有没有更好的方法？当然有！可以使用 LazyTag！

![2](./2.svg)

设想我们在操作时，仅把 [4, 7] 区间的最少覆盖区间（就像查询需要的区间一样）打上一个 “+1” 的标记，并且根据这个区间的长度计算他应该有的值，然后合并上去，根据上节课 query 的复杂度类推，这个操作的复杂度应为 O(Log N) 的。

但有个问题，现在这种处理方法查询 [1, 7] 或者 [4, 7] 这些区间都没有问题，但如果我们要查询 [4, 6] 呢？容易发现对于区间 [4, 6]，它的最小覆盖区间是 [4, 5] 与 [6, 6] 而不是 [4, 7]，我们的 Tag 并没有对下面的节点生效。

下面我们就要用到 LazyTag 除了 Tag 外的另一个性质：Lazy。

![3](./3.svg)

我们规定在查询到某个节点时，如果当前节点上有一个加法的 Tag，就把它分发给下面的节点，下面的节点同样接收这个 Tag 并且根据自己的长度计算出自己应有的值。上图展示了在查询区间 [4, 6] 的结果时发生的 Tag 向下分发的操作。非常符合直觉的，叶子节点接收 Tag 之后可以直接转换为自身的改变而不需要再保留 Tag。

容易发现像这样的“懒惰下推 Tag”的方法可以保证每次修改的操作在 O(Log N) 的时间内完成，还可以保证查询时可以查询到正确的结果！

注：可能有些同学会疑问如果 Tag 重叠会怎么样，如果我们尝试一下就可以发现上文的这种加法 Tag 之间其实具有良好的合并性，不影响该节点总和的计算。

让我们来试试代码实现吧！

## 实现

### 说在前面

上节课在使用 let 解构 Node 时，我们是可以确定要解构的 enum 一定不是 Nil，但编译器是不能确定这一点的的，所以如果我们尝试这样去解构它：

```moonbit
let Node(x, y) = z
```

会发现编译器实际上给我们了一个警告，因为不影响运行并且语义简洁，所以笔者并没有删除这种写法。

但在本文发表之前 MoonBit 推出了新的 guard 语句，我们可以用 guard let 这种方法来更好的解决这种需求：

```moonbit
guard let Node(x, y) = z
```

### 基础定义

上节课的代码当中使用 enum 定义了线段树，但是每个 enum 当中的每个元素是用来干什么的其实没有名称标识，因为数据量比较小，对我们的心智负担影响不大，但目前我们需要添加 Tag 和 Length 属性存储，会显得匹配和定义的时候无法区分参数。

我们可以使用 enum 的 labeled-argument 写法来完成更好的定义：

```moonbit
enum Data {
  Data(~sum : Int, ~len : Int)
} derive(Show)

enum LazyTag {
  Nil
  Tag(Int)
} derive(Show)

enum Node {
  Nil
  Node(~data : Data, ~tag : LazyTag, ~left : Node, ~right : Node)
} derive(Show)
```

这样我们就清晰地完成了对数据、LazyTag 和节点结构的定义，在下面初始化与模式匹配时将会更加清晰。

另外，我们把 Data 类型单独抽象出来，比上节课多了一个 len 属性，用来标记当前区间的长度，以配合 Tag 计算当前节点的值。

### 建树

我们依然像上一节一样在编写建树逻辑之前需要先考虑 Node 类型之间的加法，但本节中因为我们单独抽象了 Data，所以也要考虑他们之间的加法：

```moonbit
fn op_add(self : Data, v : Data) -> Data {
  match (self, v) {
    (Data(sum=a, len=len_a), Data(sum=b, len=len_b)) =>
      Data(sum=a + b, len=len_a + len_b)
  }
}

fn op_add(self : Node, v : Node) -> Node {
  match (self, v) {
    (Node(data=l, ..), Node(data=r, ..)) =>
      Node(data=l + r, tag=Nil, left=self, right=v)
    (Node(_), Nil) => self
    (Nil, Node(_)) => v
    (Nil, Nil) => Nil
  }
}
```

可以发现这里暂时还没有考虑 LazyTag 的合并，而是认为他们加法的结果得到的节点的 LazyTag 均为 Nil，这是很好理解的，如果已经走到一个节点，那么它的父节点当然会是没有 LazyTag 的。

接下来就可以写出建树的代码，这与上节非常相似：

```moonbit
fn build(data : ArrayView[Int]) -> Node {
  if data.length() == 1 {
    Node(data=Data(sum=data[0], len=1), tag=Nil, left=Nil, right=Nil)
  } else {
    let mid = (data.length() + 1) >> 1
    build(data[0:mid]) + build(data[mid:])
  }
}
```

## LazyTag 与区间修改的实现

我们把一个节点接受一个 LazyTag 的行为定义为 apply，容易发现其实真正的核心逻辑就在这里，当前接受上方 LazyTag 的节点身上不一定是否有 LazyTag，而如果有，又应该怎么合并？怎么根据 LazyTag 计算当前节点新的值？答案都在这个操作当中。

一个很好的实现方法是我们对 LazyTag 再单独定义一套加法运算来实现他们的合并，然后为 Node 类型编写一个 apply 函数来接收一个 LazyTag。

```moonbit
fn op_add(self : LazyTag, v : LazyTag) -> LazyTag {
  match (self, v) {
    (Tag(a), Tag(b)) => Tag(a + b)
    (Nil, t) | (t, Nil) => t
  }
}

fn apply(self : Node, v : LazyTag) -> Node {
  match (self, v) {
    (Node(data=Data(sum=a, len=length), ~tag, ~left, ~right), Tag(v) as new_tag) =>
      Node(
        data=Data(sum=a + v * length, len=length),
        tag=tag + new_tag,
        ~left,
        ~right,
      )   
    (_, Nil) => self
    (Nil, _) => Nil
  }
}
```

这是我们这节课最核心的地方，根据当前区间长度和 LazyTag 的值计算出了当前节点的正确数值，这样我们就有了 LazyTag 的实现。

那么我们如何进行区间修改呢？

```moonbit
fn modify(
  self : Node,
  l : Int,
  r : Int,
  modify_l : Int,
  modify_r : Int,
  tag : LazyTag
) -> Node {
  if modify_l > r || l > modify_r {
    self
  } else if modify_l <= l && modify_r >= r {
    self.apply(tag)
  } else {
    guard let Node(~left, ~right, ..) = self
    left.apply(tag) + right.apply(tag)
  }
}
```

逻辑实际上与上节课编写的 query 大差不差，只是每个地方都让对应的节点 apply 了我们需要修改的值（作为 LazyTag）。

不过写到这里我们可以发现，这棵线段树就算加入了区间修改之后居然还是一个可持久化的，或者说 Immutable 的线段树！我们的 modify 函数将会返回最新的那棵线段树，并没有对原来的线段树作任何改变，而我们的递归与合并语义非常明显的体现了这一点。

这说明在一些 Immutable 的需求上上采用这类写法（ADT(enum)、递归）是非常优雅而且自然的。而且 MoonBit 语言存在垃圾回收机制 (GC)，所以在无限递归的 ADT(enum) 当中不需要**显式地**用指针来指代一些关系，我们并不需要关心内存里面发生了什么。

很多对函数式编程语言不熟悉的读者可能使用 MoonBit 时没有太关注到这个问题，但其实我们一直从中受益，比如如果我们需要在 Rust 当中使用 ADT(enum) 来写一个 ConsList，我们往往需要：

```rust
enum List<T> {
    Cons(T, Box<List<T>>),
    Nil,
}
```

但在 MoonBit，我们只需要：

```moonbit
enum List[T] {
  Cons(T, List[T])
  Nil
}
```

GC is really interesting!

### 查询

查询部分只要记得需要下推 LazyTag 即可。

```moonbit
let empty_node : Node = Node(
  data=Data(sum=0, len=0),
  tag=Nil,
  left=Nil,
  right=Nil,
)

fn query(self : Node, l : Int, r : Int, query_l : Int, query_r : Int) -> Node {
  if query_l > r || l > query_r {
    empty_node
  } else if query_l <= l && query_r >= r {
    self
  } else {
    guard let Node(~tag, ~left, ~right, ..) = self
    let mid = (l + r) >> 1
    left.apply(tag).query(l, mid, query_l, query_r) +
    right.apply(tag).query(mid + 1, r, query_l, query_r)
  }
}
```

## 总结

到这里我们就完成了一棵支持区间修改的，更加完美的线段树！

接下来，在最后一节课当中我们将会学习如何给当前这棵线段树再加入一个 “乘法操作”，以及探索一些 Immutable 线段树的应用场景。感兴趣的读者可以提前自行了解。

​本篇编程实践完整代码[见此处](https://github.com/moonbit-community/MoonBit-SegmentTree/blob/main/2/main.mbt)
