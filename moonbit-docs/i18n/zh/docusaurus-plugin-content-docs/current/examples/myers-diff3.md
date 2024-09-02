# 如何用 MoonBit 实现 diff? (3)

本篇文章为diff系列的第三篇。在上一篇中，我们了解了完整的myers算法及其不足之处。在本文中，我们将了解如何实现线性空间复杂度的myers算法变种。

## 分而治之

Git所使用的Myers diff线性变种采用一种叫做*Snake*(有时也叫*Middle Snake*)的概念分解整个搜索过程，一条Snake在编辑图中意味着一步左移/下移后跟0~N步对角线移动。 Myers diff的线性变种会在一条最优的编辑路径上寻找居于中间位置中间的Snake, 并通过它将整个编辑图分割为两个部分。接下来的步骤则如法炮制，分别对分割出的两块子图运用相同的技术进行分割，最终得到一条完整的编辑路径。

```bash
    0   1   2   3   4   5   6   7   8   9  10  11  12  13  14
 0  o---o---o---o---o---o---o
    |   |   |   |   |   |   |
 1  o---o---o---o---o---o---o
    |   | \ |   |   |   |   |
 2  o---o---o---o---o---o---o
    |   |   |   |   |   |   |
 3  o---o---o---o---o---o---o
    |   |   |   |   | \ |   |
 4  o---o---o---o---o---o---o
    |   |   |   |   |   |   |
 5  o---o---o---o---o---o---o
                              \
 6                              @
                                  \
 7                                  @---o---o---o---o---o---o
                                        |   |   |   |   |   |
 8                                      o---o---o---o---o---o
                                        | \ |   |   |   |   |
 9                                      o---o---o---o---o---o
                                        |   |   |   |   |   |
10                                      o---o---o---o---o---o
                                        |   |   |   |   |   |
11                                      o---o---o---o---o---o
                                        |   |   | \ |   |   |
12                                      o---o---o---o---o---o
                                        |   |   |   |   |   |
13                                      o---o---o---o---o---o
                                        |   |   |   |   | \ |
14                                      o---o---o---o---o---o
```

> 稍微回顾一下前文，最优编辑路径指的是到终点距离最短(对角线距离为零)，这样的编辑路径不止一条。

细心的读者想必已经发现了，以上论述存在先有鸡还是先有蛋的问题：要得到一条Snake, 必须先有一条最优的编辑路径，但是要得到一条最优的编辑路径，目前看来唯一的办法是跑一遍原版myers算法。

实际上，线性myers算法的思路基本就是这样，但它采取了一种不大寻常的思路：同时从左上角和右下角使用原版myers算法交替进行搜索，但是不保存历史记录，只检查两边的搜索过程是否重叠，一旦重叠，就将重叠部分作为Middle Snake返回。

听起来思路很清晰，但还有些细节需要搞清楚。

从后往前搜索时，对角线坐标就不能再用k了，我们需要定义一个新的对角线坐标**c = k - delta**。它和k是互为镜像的，这样正好满足从反方向向起点搜索的需求。

```bash
        x                       k
                                  0     1     2     3
        0     1     2     3         \     \     \     \
  y  0  o-----o-----o-----o           o-----o-----o-----o
        |     |     |     |      -1   |     |     |     | \
        |     |     |     |         \ |     |     |     |   2
     1  o-----o-----o-----o           o-----o-----o-----o
        |     | \   |     |      -2   |     | \   |     | \
        |     |   \ |     |         \ |     |   \ |     |   1
     2  o-----o-----o-----o           o-----o-----o-----o
                                        \     \     \     \
                                        -3    -2    -1      0
                                                              c
```

如何判断搜索过程是否重叠？只要发现正向搜索在某一条对角线上的位置其x正好比反向的位置要大就行，但是由于同一条对角线的k和c坐标不同，换算会稍微有点麻烦。

### 代码实现

我们首先定义`Snake`和`Box`类型，分别对应middle snake以及被分割出的子编辑图(因为是方形的，所以直接以Box称呼了)

```rust
struct Box {
  left : Int
  right : Int
  top : Int
  bottom : Int
} derive(Debug, Show)

struct Snake {
  start : (Int, Int)
  end : (Int, Int)
} derive(Debug, Show)

fn width(self : Box) -> Int {
  self.right - self.left
}

fn height(self : Box) -> Int {
  self.bottom - self.top
}

fn size(self : Box) -> Int {
  self.width() + self.height()
}

fn delta(self : Box) -> Int {
  self.width() - self.height()
}
```

为了避免太早陷入细节，我们先假设已经有了能找到middle snake的函数`midpoint : (Box, Array[Line], Array[Line]) -> Snake?`, 然后在此基础上编写能搜索出完整path的函数`find_path`。

```rust
fn find_path(box : Box, a : Array[Line], b : Array[Line]) -> Iter[(Int, Int)]? {
  let snake = midpoint(box, a, b)?
  let start = snake.start
  let end = snake.end
  let headbox = Box::{ left : box.left, top : box.top, right : start.0, bottom : start.1 }
  let tailbox = Box::{ left : end.0, top : end.1, right : box.right, bottom : box.bottom }
  // println("snake = \{snake}")
  // println("headbox = \{headbox}")
  // println("tailbox = \{tailbox}")
  let head = find_path(headbox, a, b).or(Iter::singleton(start))
  let tail = find_path(tailbox, a, b).or(Iter::singleton(end))
  Some(head.concat(tail))
}
```

`find_path`的实现非常简单直接，而`midpoint`就要复杂一些

- 对于大小为0的Box, 直接返回None

- 计算搜索范围的边界，由于前向和后向搜索各搜一半故除以二，但在Box大小为奇数时因为前向搜索的范围要大一点，所以结果加一。

- 前向和后向搜索的记录分两个数组保存

- 正反交替搜索，若没找到结果便返回None

```rust
fn midpoint(self : Box, a : Array[Line], b : Array[Line]) -> Snake? {
  if self.size() == 0 {
    return None
  }
  let max = {
    let half = self.size() / 2
    if is_odd(self.size()) {
      half + 1
    } else {
      half
    }
  }
  let vf = BPArray::make(2 * max + 1, 0)
  vf[1] = self.left
  let vb = BPArray::make(2 * max + 1, 0)
  vb[1] = self.bottom
  for d = 0; d < max + 1; d = d + 1 {
    match forward(self, vf, vb, d, a, b) {
      None =>
      match backward(self, vf, vb, d, a, b) {
        None => continue
        res => return res
      }
      res => return res
    }
  } else {
    None
  }
}
```

前向/后向搜索的过程相比原本的myers算法做出了一些需要略作解释的改动

- 由于需要返回snake，搜索过程需要算出上一个坐标(px在这里指previous x)

- 由于现在的搜索过程在一个Box中工作(不是全局的编辑图)，从x计算y(或者反过来)要考虑换算

- 后向搜索过程选择最小化y只是一种启发策略，改成x也行

```rust
fn forward(self : Box, vf : BPArray[Int], vb : BPArray[Int], d : Int, a : Array[Line], b : Array[Line]) -> Snake? {
  for k = d; k >= -d; k = k - 2 {
    let c = k - self.delta()
    let mut x = 0
    let mut px = 0
    if k == -d || (k != d && vf[k - 1] < vf[k + 1]) {
      x = vf[k + 1]
      px = x
    } else {
      px = vf[k - 1]
      x = px + 1
    }
    let mut y = self.top + (x - self.left) - k
    let py = if (d == 0 || x != px) { y } else { y - 1 }
    while x < self.right && y < self.bottom && a[x].text == b[y].text {
      x = x + 1
      y = y + 1
    }
    vf[k] = x
    if is_odd(self.delta()) && (c >= -(d - 1) && c <= d - 1) && y >= vb[c] {
      return Some(Snake::{ start : (px, py), end : (x, y) })
    }
  }
  return None
}

fn backward(self : Box, vf : BPArray[Int], vb : BPArray[Int], d : Int, a : Array[Line], b : Array[Line]) -> Snake? {
  for c = d; c >= -d; c = c - 2 {
    let k = c + self.delta()
    let mut y = 0
    let mut py = 0
    if c == -d || (c != d && vb[c - 1] > vb[c + 1]) {
      y = vb[c + 1]
      py = y
    } else {
      py = vb[c - 1]
      y = py - 1
    }
    let mut x = self.left + (y - self.top) + k
    let px = if (d == 0 || y != py) { x } else { x + 1 }
    while x > self.left && y > self.top && a[x - 1].text == b[y - 1].text {
      x = x - 1
      y = y - 1
    }
    vb[c] = y
    if is_even(self.delta()) && (k >= -d && k <= d) && x <= vf[k] {
      return Some(Snake::{ start : (x, y), end : (px, py) })
    }
  }
  return None
}
```

## 尾声

实际上，Git在默认的diff算法之外还提供了另一种diff算法可以选用：patience diff，它和myers diff的思路截然不同，有时能产出可读性更高的diff结果。
