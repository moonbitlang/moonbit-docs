# Myers diff 2

This is the second post in the diff series. In the [previous one](https://www.moonbitlang.com/docs/examples/myers-diff), we learned how to transform the process of computing diffs into a graph search problem and how to search for the shortest edit distance. In this article, we will learn how to extend the search process from the previous post to obtain the complete edit sequence.

## Recording the Search Process

The first step to obtaining the complete edit sequence is to save the entire editing process. This step is relatively simple; we just need to save the current search depth `d` and the graph node with depth `d` at the beginning of each search round.

```rust
fn shortest_edit(a : Array[Line], b : Array[Line]) -> Array[(BPArray[Int], Int)] {
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
    push(v.copy(), d) // Save search depth and node
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

## Backtracking the Edit Path

After recording the entire search process, the next step is to walk back from the endpoint to find the path taken. But before we do that, let's first define the `Edit` type.

```rust
enum Edit {
  Insert(~new : Line)
  Delete(~old : Line)
  Equal(~old : Line, ~new : Line) // old, new
} derive(Debug, Show)
```

Next, let's perform the backtracking.

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

The method of backtracking is essentially the same as forward search, just in reverse.

- Calculate the current `k` value using `x` and `y`.

- Access the historical records and use the same judgment criteria as in forward search to find the `k` value at the previous search round.

- Restore the coordinates of the previous search round.

- Try free movement and record the corresponding edit actions.

- Determine the type of edit that caused the change in `k` value.

- Continue iterating.

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

Combining the two functions, we get a complete `diff` implementation.

```rust
fn diff(a : Array[Line], b : Array[Line]) -> Array[Edit] {
  let trace = shortest_edit(a, b)
  backtrack(a, b, trace)
}
```

## Printing the Diff

To print a neat diff, we need to left-align the text. Also, due to the order issue during backtracking, we need to print from back to front.

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
      "\(tag) \(old_line) \(new_line)    \(text)"
    }
    Delete(_) as edit => {
      let tag = "-"
      let old_line = pad_right(edit.old.number.to_string(), line_width)
      let new_line = pad_right("", line_width)
      let text = edit.old.text
      "\(tag) \(old_line) \(new_line)    \(text)"
    }
    Equal(_) as edit => {
      let tag = " "
      let old_line = pad_right(edit.old.number.to_string(), line_width)
      let new_line = pad_right(edit.new.number.to_string(), line_width)
      let text = edit.old.text
      "\(tag) \(old_line) \(new_line)    \(text)"
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

The result is as follows:

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

## Conclusion

The Myers algorithm demonstrated above is complete, but due to the frequent copying of arrays, it has a very large space overhead. Therefore, most software like Git uses a linear variant of the diff algorithm (found in the appendix of the original paper). This variant may sometimes produce diffs of lower quality (harder for humans to read) than the standard Myers algorithm but can still ensure the shortest edit sequence.
