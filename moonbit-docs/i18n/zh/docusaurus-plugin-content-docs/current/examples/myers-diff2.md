# 如何用 MoonBit 实现 diff? (2)

本篇文章为diff系列的第二篇。在[上一篇](https://www.moonbitlang.cn/docs/examples/myers-diff)中，我们了解了如何将计算diff的过程转换为图上的搜索问题，以及如何搜索最短编辑距离。在本文中，我们将了解如何对前文的搜索过程进行扩展，得到完整的编辑序列。

## 记录搜索过程

得到完整编辑序列的第一步是保存整个编辑过程。这一步较为简单，我们只需要在每一轮搜索的开始将当前搜索深度d与深度为d的图节点保存起来即可。

```rust
fn shortst_edit(a : Array[Line], b : Array[Line]) -> Array[(BPArray[Int], Int)] {
  let n = a.length()
  let m = b.length()
  let max = n + m
  let v = BPArray::make(2 * max + 1, 0)
  let trace = []
  fn push(v : BPArray[Int], d : Int) -> Unit {
    trace.push((v, d))
  }
  // v[1] = 0
  for d = 0; d < max + 1; d = d + 1 {
    push(v.copy(), d) // 保存搜索深度与节点
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
        return trace
      }
    }
  } else {
    abort("impossible")
  }
}
```

## 回溯编辑路径

在得到整个搜索过程的记录之后，下一步是从终点往回走，找到来时的那条路。不过在这之前，让我们先定义一下`Edit`类型

```rust
enum Edit {
  Insert(~new : Line)
  Delete(~old : Line)
  Equal(~old : Line, ~new : Line) // old, new
} derive(Debug, Show)
```

接着进行回溯

```rust
fn backtrack(a : Array[Line], b : Array[Line], trace : Array[(BPArray[Int], Int)]) -> Array[Edit] {
  let mut x = a.length()
  let mut y = b.length()
  let edits = []
  fn push(edit : Edit) -> Unit {
    edits.push(edit)
  }
  ......
```

回溯的方法和正向搜索的思路基本相同，只是把方向倒了过来。

- 通过x和y计算出当前k值

- 通过访问历史记录，用跟正向搜索时一样的判断条件找出上一轮搜索所处位置的k值

- 还原上一轮搜索所处位置坐标

- 尝试自由移动并记录对应的编辑动作

- 判断导致k值改变的编辑是哪一种

- 继续迭代

```rust
  for i = trace.length() - 1; i >= 0; i = i - 1 {
    let (v, d) = trace[i]
    let k = x - y
    let prev_k = if k == -d || (k != d && v[k - 1] < v[k + 1]) {
      k + 1
    } else {
      k - 1
    }
    let prev_x = v[prev_k]
    let prev_y = prev_x - prev_k
    while x > prev_x && y > prev_y {
      x = x - 1
      y = y - 1
      push(Equal(old = a[x], new = b[y]))
    }
    if d > 0 {
      if x == prev_x {
        push(Insert(new = b[prev_y]))
      } else if y == prev_y {
        push(Delete(old = a[prev_x]))
      }
      x = prev_x
      y = prev_y
    }
  }
```

将两个函数组合一下，我们得到了完整的`diff`实现

```rust
fn diff(a : Array[Line], b : Array[Line]) -> Array[Edit] {
  let trace = shortst_edit(a, b)
  backtrack(a, b, trace)
}
```

## 打印diff

要打印较为漂亮的diff，需要为文本做左对齐。同时由于此前回溯时的顺序问题，需要从后往前打印。

```rust
let line_width = 4

fn pad_right(s : String, width : Int) -> String {
  String::make(width - s.length(), ' ') + s
}

fn print_edit(edit : Edit) -> String {
  match edit {
    Insert(_) as edit => {
      let tag = "+"
      let old_line = pad_right("", line_width)
      let new_line = pad_right(edit.new.number.to_string(), line_width)
      let text = edit.new.text
      "\{tag} \{old_line} \{new_line}    \{text}"
    }
    Delete(_) as edit => {
      let tag = "-"
      let old_line = pad_right(edit.old.number.to_string(), line_width)
      let new_line = pad_right("", line_width)
      let text = edit.old.text
      "\{tag} \{old_line} \{new_line}    \{text}"
    }
    Equal(_) as edit => {
      let tag = " "
      let old_line = pad_right(edit.old.number.to_string(), line_width)
      let new_line = pad_right(edit.new.number.to_string(), line_width)
      let text = edit.old.text
      "\{tag} \{old_line} \{new_line}    \{text}"
    }
  }
}

fn print_diff(diff : Array[Edit]) -> Unit {
  for i = diff.length() - 1; i >= 0; i = i - 1 {
    diff[i]
    |> print_edit
    |> println
  }
}
```

结果如下：

```diff
-    1         A
-    2         B
     3    1    C
+         2    B
     4    3    A
     5    4    B
-    6         B
     7    5    A
+         6    C
```

## 尾声

以上所展示的myers算法是完整的，但由于需要频繁复制数组，它的空间占用非常大，所以Git等软件实际使用的diff算法大多是它的一种线性变种(在原论文的附录中可以找到)。这种变种所产生的diff有时会比标准的myers算法在质量上差一些(对人来说不太好读)，但仍可以保证是最短编辑序列。
