# Myers diff 3

This article is the third in the [diff series](index.md). In the [previous part](myers-diff2.md), we explored the full Myers algorithm and its limitations. In this post, we'll learn how to implement a variant of the Myers algorithm that operates with linear space complexity.

## Divide and Conquer

The linear variant of Myers' diff algorithm used by Git employs a concept called the *Snake* (sometimes referred to as the *Middle Snake*) to break down the entire search process. A Snake in the edit graph represents a diagonal movement of 0 to N steps after a single left or down move. The linear Myers algorithm finds the middle Snake on the optimal edit path and uses it to divide the entire edit graph into two parts. The subsequent steps apply the same technique to the resulting subgraphs, eventually producing a complete edit path.

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

> A quick recap: The optimal edit path is the one that has the shortest distance to the endpoint (a diagonal distance of zero), and there can be more than one such path.

Attentive readers may have noticed a chicken-and-egg problem: to find a Snake, you need an optimal edit path, but to get an optimal edit path, it seems like you need to run the original Myers algorithm first.

In fact, the idea behind the linear Myers algorithm is somewhat unconventional: it alternates the original Myers algorithm from both the top-left and bottom-right corners, but without storing the history. Instead, it simply checks if the searches from both sides overlap. When they do, the overlapping portion is returned as the Middle Snake.

This approach seems straightforward, but there are still some details to sort out.

When searching from the bottom-right, the diagonal coordinate can no longer be referred to as *k*. We need to define a new diagonal coordinate **c = k - delta**. This coordinate is the mirror image of *k*, perfectly suited for reverse direction search.

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

How do we determine if the searches overlap? Simply check if the position on a diagonal line in the forward search has an *x* value greater than that in the reverse search. However, since the *k* and *c* coordinates differ for the same diagonal, the conversion can be a bit tricky.

### Code Implementation

We'll start by defining `Snake` and `Box` types, representing the middle snake and the sub-edit graphs (since they're square, we call them `Box`).

```moonbit
///
struct Box {
  left : Int
  right : Int
  top : Int
  bottom : Int
} derive(Show)

///|
struct Snake {
  start : (Int, Int)
  end : (Int, Int)
} derive(Show)

///|
fn Box::width(self : Self) -> Int {
  self.right - self.left
}

///|
fn Box::height(self : Self) -> Int {
  self.bottom - self.top
}

///|
fn Box::size(self : Self) -> Int {
  self.width() + self.height()
}

///|
fn Box::delta(self : Self) -> Int {
  self.width() - self.height()
}

```

To avoid getting bogged down in details too early, let's assume we already have a function `midpoint : (Box, Array[Line], Array[Line]) -> Snake?` to find the middle snake. Then, we can build the function `find_path` to search for the complete path.

```moonbit
///
fn Box::find_path(
  box : Self,
  old~ : Array[Line],
  new~ : Array[Line],
) -> Iter[(Int, Int)]? {
  guard box.midpoint(old~, new~) is Some(snake) else { None }
  let start = snake.start
  let end = snake.end
  let headbox = Box::{
    left: box.left,
    top: box.top,
    right: start.0,
    bottom: start.1,
  }
  let tailbox = Box::{
    left: end.0,
    top: end.1,
    right: box.right,
    bottom: box.bottom,
  }
  let head = headbox.find_path(old~, new~).unwrap_or(Iter::singleton(start))
  let tail = tailbox.find_path(old~, new~).unwrap_or(Iter::singleton(end))
  Some(head.concat(tail))
}
```

The implementation of `find_path` is straightforward, but `midpoint` is a bit more complex:

- For a `Box` of size 0, return `None`.
- Calculate the search boundaries. Since forward and backward searches each cover half the distance, divide by two. However, if the size of the `Box` is odd, add one more to the forward search boundary.
- Store the results of the forward and backward searches in two arrays.
- Alternate between forward and backward searches, returning `None` if no result is found.

```moonbit

///|
fn Box::midpoint(self : Self, old~ : Array[Line], new~ : Array[Line]) -> Snake? {
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
    match self.forward(forward=vf, backward=vb, d, old~, new~) {
      None =>
        match self.backward(forward=vf, backward=vb, d, old~, new~) {
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

The forward and backward searches have some modifications compared to the original Myers algorithm, which need a bit of explanation:

- Since we need to return the snake, the search process must calculate the previous coordinate (`px` stands for previous x).
- The search now works within a `Box` (not the global edit graph), so calculating `y` from `x` (or vice versa) requires conversion.
- The backward search minimizes `y` as a heuristic strategy, but minimizing `x` would also work.

```moonbit

///|
fn Box::forward(
  self : Self,
  forward~ : BPArray[Int],
  backward~ : BPArray[Int],
  depth : Int,
  old~ : Array[Line],
  new~ : Array[Line],
) -> Snake? {
  for k = depth; k >= -depth; k = k - 2 {
    let c = k - self.delta()
    let mut x = 0
    let mut px = 0
    if k == -depth || (k != depth && forward[k - 1] < forward[k + 1]) {
      x = forward[k + 1]
      px = x
    } else {
      px = forward[k - 1]
      x = px + 1
    }
    let mut y = self.top + (x - self.left) - k
    let py = if depth == 0 || x != px { y } else { y - 1 }
    while x < self.right && y < self.bottom && old[x].text == new[y].text {
      x = x + 1
      y = y + 1
    }
    forward[k] = x
    if is_odd(self.delta()) &&
      (c >= -(depth - 1) && c <= depth - 1) &&
      y >= backward[c] {
      return Some(Snake::{ start: (px, py), end: (x, y) })
    }
  }
  return None
}

///|
fn Box::backward(
  self : Self,
  forward~ : BPArray[Int],
  backward~ : BPArray[Int],
  depth : Int,
  old~ : Array[Line],
  new~ : Array[Line],
) -> Snake? {
  for c = depth; c >= -depth; c = c - 2 {
    let k = c + self.delta()
    let mut y = 0
    let mut py = 0
    if c == -depth || (c != depth && backward[c - 1] > backward[c + 1]) {
      y = backward[c + 1]
      py = y
    } else {
      py = backward[c - 1]
      y = py - 1
    }
    let mut x = self.left + (y - self.top) + k
    let px = if depth == 0 || y != py { x } else { x + 1 }
    while x > self.left && y > self.top && old[x - 1].text == new[y - 1].text {
      x = x - 1
      y = y - 1
    }
    backward[c] = y
    if is_even(self.delta()) && (k >= -depth && k <= depth) && x <= forward[k] {
      return Some(Snake::{ start: (x, y), end: (px, py) })
    }
  }
  return None
}
```

## Conclusion

In addition to the default diff algorithm, Git also offers another diff algorithm called patience diff. It differs significantly from Myers diff in approach and sometimes produces more readable diff results.
