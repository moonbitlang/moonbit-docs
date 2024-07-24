# 如何用 MoonBit 实现 diff?

**你使用过 Unix 下的小工具 diff 吗？**

没有也没关系，简而言之，它是一个比对两个文本文件之间有什么不同之处的工具。它的作用不止于此，Unix 下还有一个叫 patch 的小工具。

时至今日，很少有人手动为某个软件包打补丁了，但 diff 在另一个地方仍然保留着它的作用：版本管理系统。能够看见某一次提交之后的源码文件发生了哪些变化(并且用不同颜色标出来)是个很有用的功能。我们以当今最流行的版本管理系统 git 为例，它可以：

```diff
diff --git a/main/main.mbt b/main/main.mbt
index 99f4c4c..52b1388 100644
--- a/main/main.mbt
+++ b/main/main.mbt
@@ -3,7 +3,7 @@

 fn main {
   let a = lines("A\nB\nC\nA\nB\nB\nA")
-  let b = lines("C\nB\nA\nB\nA\nC")
+  let b = lines("C\nB\nA\nB\nA\nA")
   let r = shortst_edit(a, b)
   println(r)
 }

```

但是，究竟怎样计算出两个文本文件的差别呢？

git 的默认 diff 算法是 **Eugene W. Myers**在他的论文**_An O(ND) Difference Algorithm and Its Variations_** 中所提出的，这篇论文的 pdf 可以在网上找到，但论文内容主要集中于证明该算法的正确性。

在下文中，我们将以不那么严谨的方式了解该算法的基本框架，并且使用 MoonBit 编写该算法的一个简单实现。

## **01 定义"差别"及其度量标准**

当我们谈论两段文本的"差别"时，我们说的其实是一系列的编辑动作，通过执行这段动作，我们可以把文本 a 转写成文本 b。

假设文本 a 的内容是：

```
A
B
C
A
B
B
A

```

文本 b 的内容是：

```
C
B
A
B
A
C

```

要把文本 a 转写成文本 b，最简单的编辑序列是删除每一个 a 中的字符（用减号表示），然后插入每一个 b 中的字符（用加号表示）。

```diff
- A
- B
- C
- A
- B
- B
- A
+ C
+ B
+ A
+ B
+ A
+ C

```

但这样的结果对阅读代码的程序员可能没有什么帮助，而下面这个编辑序列就好很多，至少它比较短。

```diff
- A
- B
  C
+ B
  A
  B
- B
  A
+ C

```

实际上，它是最短的可以将文本 a 转写成文本 b 的编辑序列之一，总共有5个动作。如果仅仅以编辑序列长度作为衡量标准，这个结果足以让我们满意。但当我们审视现实中已经存在的各种编程语言，我们会发现在此之外还有一些对用户体验同样重要的指标，让我们看看下面这两个例子：

```diff
// 质量好
  struct RHSet[T] {
    set : RHTable[T, Unit]
  }
+
+ fn RHSet::new[T](capacity : Int) -> RHSet[T] {
+  let set : RHTable[T, Unit]= RHTable::new(capacity)
+  { set : set }
+ }

// 质量不好
  struct RHSet[T] {
    set : RHTable[T, Unit]
+ }
+
+ fn RHSet::new[T](capacity : Int) -> RHSet[T] {
+  let set : RHTable[T, Unit]= RHTable::new(capacity)
+  { set : set }
  }

```

当我们在文件末尾处插入了一个新的函数定义，那计算出的编辑序列最好把更改都集中在后面。还有些类似的情况，当同时存在删除和插入时，最好不要计算出一个两种操作交织穿插的编辑序列，下面是另一个例子。

```
Good:   - one         Bad:    - one
        - two                 + four
        - three               - two
        + four                + five
        + five                + six
        + six                 - three

```

myers 的 diff 算法能够满足我们在上面提到的这些需求，它是一种贪心算法，会尽可能地跳过相同的行（避免了在 `{` 前面插入文本的情况），同时它还会尽可能地把删除安排在插入前面，这又避免了后面一种情况。

## **02 算法概述**

Myers 论文的基本想法是构建一张编辑序列构成的网格图，然后在这条图上搜索一条最短路径。我们沿用上面的例子 a = ABCABBA 和 b = CBABAC，建立一个 (x, y) 坐标网格。

```
    0     1     2     3     4     5     6     7

0   o-----o-----o-----o-----o-----o-----o-----o
    |     |     | \   |     |     |     |     |
    |     |     |  \  |     |     |     |     |   C
    |     |     |   \ |     |     |     |     |
1   o-----o-----o-----o-----o-----o-----o-----o
    |     | \   |     |     | \   | \   |     |
    |     |  \  |     |     |  \  |  \  |     |   B
    |     |   \ |     |     |   \ |   \ |     |
2   o-----o-----o-----o-----o-----o-----o-----o
    | \   |     |     | \   |     |     | \   |
    |  \  |     |     |  \  |     |     |  \  |   A
    |   \ |     |     |   \ |     |     |   \ |
3   o-----o-----o-----o-----o-----o-----o-----o
    |     | \   |     |     | \   | \   |     |
    |     |  \  |     |     |  \  |  \  |     |   B
    |     |   \ |     |     |   \ |   \ |     |
4   o-----o-----o-----o-----o-----o-----o-----o
    | \   |     |     | \   |     |     | \   |
    |  \  |     |     |  \  |     |     |  \  |   A
    |   \ |     |     |   \ |     |     |   \ |
5   o-----o-----o-----o-----o-----o-----o-----o
    |     |     | \   |     |     |     |     |
    |     |     |  \  |     |     |     |     |   C
    |     |     |   \ |     |     |     |     |
6   o-----o-----o-----o-----o-----o-----o-----o

       A     B     C     A     B     B     A

```

这张网格中左上方为起点(0, 0)， 右下方为终点(7, 6)。沿着 x 轴向右前进一步为删除 a 中对应位置文本，沿 y 轴向下前进一步为插入 b 中对应位置文本，对角斜线标记的则是相同的文本，这些斜线可以直接跳过，它们不会触发任何编辑。

在编写实际执行搜索的代码之前，让我们先手动执行两轮搜索：

- 第一轮搜索起点为(0, 0)，移动一步可以到达(0,1)和(1,0)。
- 第二轮搜索起点为(0,1)和(1,0)，从(0,1)出发下移可以到达(0,2)， 但是那里有一条通向(1,3)的斜线，所以最终落点为(1,3)。

## **03 实现**

虽然我们已经敲定了算法的基本思路，但仍有一些关键的设计需要考虑。算法的输入是两个字符串，但搜索需要在图上进行，如果真的把图构造出来再去搜索，这既非常浪费内存，也很费时间。

myers 算法的实现使用了一个聪明的想法，它定义了一个新的坐标 k = x - y。

- 右移一步会让k加一
- 左移一步会让k减一
- 沿对角线向左下方移动k值不变

让我们再定义一个坐标 d 用于代表搜索的深度，以 d 为横轴 k 为纵轴画出搜索过程的树状图：

```
    |      0     1     2     3     4     5
----+--------------------------------------
    |
 4  |                             7,3
    |                           /
 3  |                       5,2
    |                     /
 2  |                 3,1         7,5
    |               /     \     /     \
 1  |           1,0         5,4         7,6
    |         /     \           \
 0  |     0,0         2,2         5,5
    |         \                       \
-1  |           0,1         4,5         5,6
    |               \     /     \
-2  |                 2,4         4,6
    |                     \
-3  |                       3,6

```

可以看出来，在每一轮搜索中，k都严格地处于[-d, d]区间中(因为一次移动中最多也就能在上一轮的基础上加一或者减一), 且各点之间的k值间隔为2。myers算法的基本思路便源于此：通过遍历d和k进行搜索。当然了，它还需要保存每轮搜索的x坐标供下一轮搜索使用。

让我们首先定义Line结构体，它表示文本中的一行。

```rust
struct Line {
  number : Int // 行号
  text : String // 不包含换行
} derive(Debug, Show)

fn Line::new(number : Int, text : String) -> Line {
  Line::{ number : number, text : text }
}

```

然后定义一个辅助函数，它将一个字符串按照换行符分割成 Array[Line]。这里需要注意的是，行号是从1开始的。

```rust
fn lines(str : String) -> Array[Line] {
  let mut line_number = 0
  let buf = Buffer::make(50)
  let vec = []
  for i = 0; i < str.length(); i = i + 1 {
    let ch = str[i]
    buf.write_char(ch)
    if ch == '\n' {
      let text = buf.to_string()
      buf.reset()
      line_number = line_number + 1
      vec.push(Line::new(line_number, text))
    }
  } else {
    // 可能文本不以换行符为结尾
    let text = buf.to_string()
    if text != "" {
      line_number = line_number + 1
      vec.push(Line::new(line_number, text))
    }
    vec
  }
}

```

接下来我们需要包装一下数组，使其支持负数索引，原因是我们要用k的值做索引。

```rust
type BPArray[T] Array[T] // BiPolar Array

fn BPArray::make[T](capacity : Int, default : T) -> BPArray[T] {
  let arr = Array::make(capacity, default)
  BPArray(arr)
}

fn op_get[T](self : BPArray[T], idx : Int) -> T {
  let BPArray(arr) = self
  if idx < 0 {
    arr[arr.length() + idx]
  } else {
    arr[idx]
  }
}

fn op_set[T](self : BPArray[T], idx : Int, elem : T) -> Unit {
  let BPArray(arr) = self
  if idx < 0 {
    arr[arr.length() + idx] = elem
  } else {
    arr[idx] = elem
  }
}

```

现在我们可以开始编写搜索函数了，不过，搜索出完整的路径是比较复杂的，我们的第一个目标是搜索出最短路径的长度（大小和搜索深度一样）。我们先展示它的基本框架：

```rust
fn shortst_edit(a : Array[Line], b : Array[Line]) -> Int {
  let n = a.length()
  let m = b.length()
  let max = n + m
  let v = BPArray::make(2 * max + 1, 0)
  for d = 0; d < max + 1; d = d + 1 {
    for k = -d; k < d + 1; k = k + 2 {
    ......
    }
  }
}

```

通过最极端的情况(两段文本没有相同的行)可以推出最多需要搜索n + m步，最少需要搜索0步。故设变量max = n + m。数组v是以k为索引保存x值的历史记录，因为k的范围是[-d, d]，这个数组的大小被设为2 \* max + 1。

但即使到了这一步，接下来该怎么做还是挺不好想，所以我们暂且只考虑d = 0; k = 0的情况。此时一定在(0, 0)点。同时，假如两段文本的开头相同，那就允许直接跳过。我们将这一轮的最终坐标写入数组v。

```rust
if d == 0 { // d等于0 k也一定等于0
  x = 0
  y = x - k
  while x < n && y < m && a[x].text == b[y].text {
    // 跳过所有相同的行
    x = x + 1
    y = y + 1
  }
  v[k] = x
}

```

在d > 0时，就需要用到上一轮存储的坐标信息了。当我们知道一个点的k值以及上一轮搜索中点的坐标时，v[k]的值其实很好推算。因为搜索每深入一步k的值只能加一或者减一，所以v[k]在搜索树中一定是从v[k - 1]或者v[k + 1]延伸出来的。接下来的问题是：以v[k - 1]为末端的和以v[k + 1]为末端的这两条路径，应该如何选择？

有两种边界情况：k == -d和k == d

- k == -d时，只能选择v[k + 1]
- k == d时，只能选择v[k - 1]

回顾一下我们之前提到的要求：尽可能地把删除安排在插入前面，这基本上意味着我们应该选择x值最大的前一个位置。

```rust
if k == -d {
  x = v[k + 1]
} else if k == d {
  x = v[k - 1] + 1 // 横向移动需要加一
} else if v[k - 1] < v[k + 1] {
  x = v[k + 1]
} else {
  x = v[k - 1] + 1
}

```

合并一下这四个分支，我们得到这样的代码：

```rust
if k == -d || (k != d && v[k - 1] < v[k + 1]) {
  x = v[k + 1]
} else {
  x = v[k - 1] + 1
}

```

综合上面的所有步骤，我们可以得到这样的代码：

```rust
fn shortst_edit(a : Array[Line], b : Array[Line]) -> Int {
  let n = a.length()
  let m = b.length()
  let max = n + m
  let v = BPArray::make(2 * max + 1, 0)
  // v[1] = 0
  for d = 0; d < max + 1; d = d + 1 {
    for k = -d; k < d + 1; k = k + 2 {
      let mut x = 0
      let mut y = 0
      // if d == 0 {
      //   x = 0
      // }
      if k == -d || (k != d && v[k - 1] < v[k + 1]) {
        x = v[k + 1]
      } else {
        x = v[k - 1] + 1
      }
      y = x - k
      while x < n && y < m && a[x].text == b[y].text {
        x = x + 1
        y = y + 1
      }
      v[k] = x
      if x >= n && y >= m {
        return d
      }
    }
  } else {
    abort("impossible")
  }
}

```

由于数组的初始值为0，我们可以省略 d == 0 这个分支。

## **04 尾声**

我们实现了一个不完整的myers算法，它完成了正向的路径搜索，在下一篇文章中，我们将实现回溯，还原出完整的编辑路径，并写一个可以输出彩色diff的打印函数。

本篇文章参考了：_[The Myers diff algorithm: part 2](https://blog.jcoglan.com/2017/02/15/the-myers-diff-algorithm-part-2/)_

感谢这篇博客的作者James Coglan。
