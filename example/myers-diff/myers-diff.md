# Myers diff

Have you ever used the Unix tool `diff`? In short, it is a tool for comparing the differences between two text files. What's more, Unix has a tool called `patch`.

Nowadays, few people manually apply patches to software packages, but `diff` still retains its usefulness in another area: version control systems. It's quite handy to have the function of being able to see what changes have been made to source code files after a particular commit (and highlighted with different colors). Take the most popular version control system today, git, as an example:

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

But how exactly do we calculate the differences between two text files?

git's default diff algorithm was proposed by *Eugene W. Myers* in his paper **An O(ND) Difference Algorithm and Its Variations**. This paper mainly focuses on proving the correctness of the algorithm. In the following text, we will understand the basic framework of this algorithm in a less rigorous way and use MoonBit to write a simple implementation.

## Defining "Difference" and Its Measurement Criteria

When we talk about the "difference" between two text files, what we are actually referring to is a series of editing steps that can transform text a into text b.

Assume the content of text a is

```default
A
B
C
A
B
B
A
```

Assume the content of text b is

```default
C
B
A
B
A
C
```

To transform text a into text b, the simplest edit sequence is to delete each character in a (indicated with a minus sign) and then insert each character in b (indicated with a plus sign).

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

But such a result might not be very helpful for programmers reading the code. The following edit sequence is much better, at least it is shorter.

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

In fact, it is one of the shortest edit sequences that can transform text a into text b, with 5 operations. If we only measure the length of the edit sequence, this result is satisfactory. But when we look at the various programming languages, we find that there are other metrics that are equally important for user experience. Let's look at the following examples:

```diff
// good quality
  struct RHSet[T] {
    set : RHTable[T, Unit]
  }
+
+ fn RHSet::new[T](capacity : Int) -> RHSet[T] {
+  let set : RHTable[T, Unit]= RHTable::new(capacity)
+  { set : set }
+ }


// bad quality
  struct RHSet[T] {
    set : RHTable[T, Unit]
+ }
+
+ fn RHSet::new[T](capacity : Int) -> RHSet[T] {
+  let set : RHTable[T, Unit]= RHTable::new(capacity)
+  { set : set }
  }
```

When we insert a new function definition at the end of a file, the calculated edit sequence should ideally locate the changes at the end. In similar cases, when there are both deletions and insertions, it is best not to calculate an edit sequence that interleaves these two operations. Here's another example.

```default
Good:   - one         Bad:    - one
        - two                 + four
        - three               - two
        + four                + five
        + five                + six
        + six                 - three
```

Myers' diff algorithm can fulfill all those requirements. It is a greedy algorithm that skips over matching lines whenever possible (avoiding inserting text before `{`), and it also tries to place deletions before insertions, avoiding the latter situation.

## Algorithm Overview

The basic idea in Myers' paper is to construct a grid graph of edit sequences and then search for the shortest path on this graph. Using the previous example `a = ABCABBA` and `b = CBABAC`, we create an `(x, y)` coordinate grid.

```default
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

The upper left of this grid is the starting point `(0, 0)`, and the lower right is the endpoint `(7, 6)`. Moving one step right along the x-axis deletes the corresponding character in a, moving one step down along the y-axis inserts the corresponding character in b, and diagonal lines indicate matching characters that can be skipped without triggering any edits.

Before writing the actual search code, let's manually perform two rounds of searching:

- The first round starts at `(0, 0)` and moves one step to reach `(0,1)` and `(1,0)`.
- The second round starts at `(0,1)` and `(1,0)`. From `(0,1)`, moving down reaches `(0,2)`, but there is a diagonal line leading to `(1,3)`, so the final point is `(1,3)`.

The entire Myers algorithm is based on this kind of breadth-first search.

## Implementation

We have outlined the basic idea, now it's time to consider the design in detail. The input to the algorithm is two strings, but the search needs to be conducted on a graph. It's a waste of both memory and time to construct the graph and then search it.

The implementation of the Myers algorithm adopts a clever approach by defining a new coordinate `k = x - y`.

- Moving right increases `k` by one.
- Moving left decreases `k` by one.
- Moving diagonally down-left keeps `k` unchanged.

Let's define another coordinate `d` to represent the depth of the search. Using `d` as the horizontal axis and `k` as the vertical axis, we can draw a tree diagram of the search process.

```default
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

You can see that in each round of searching, `k` is strictly within the range `[-d, d]` (because in one move, it can at most increase or decrease by one from the previous round), and the `k` values between points have an interval of 2. The basic idea of Myers' algorithm comes from this idea: searching by iterating over `d` and `k`. Of course, it also needs to save the `x` coordinates of each round for use in the next round of searching.

Let's first define the `Line` struct, which represents a line in the text.

```moonbit
///
struct Line {
  number : Int // Line number
  text : String // Does not include newline
} derive(Show, ToJson)

///|
fn Line::new(number : Int, text : String) -> Line {
  Line::{ number, text }
}
```

Then, define a helper function that splits a string into `Array[Line]` based on newline characters. Note that line numbers start from 1.

```moonbit
///
fn lines(str : String) -> Array[Line] {
  let lines = Array::new(capacity=50)
  let mut line_number = 0
  for line in str.split("\n") {
    line_number = line_number + 1
    lines.push(Line::new(line_number, line.to_string()))
  } else {
    return lines
  }
}
```

Next, we need to wrap the array so that it supports negative indexing because we will use the value of `k` as an index.

```moonbit
///
struct BPArray[T](Array[T]) // BiPolar Array

///|
fn[T] BPArray::make(capacity : Int, default : T) -> BPArray[T] {
  let arr = Array::make(capacity, default)
  BPArray(arr)
}

///|
fn[T] BPArray::copy(self : BPArray[T]) -> BPArray[T] {
  let BPArray(arr) = self
  BPArray(arr.copy())
}

///|
fn[T] BPArray::op_get(self : BPArray[T], idx : Int) -> T {
  let BPArray(arr) = self
  if idx < 0 {
    arr[arr.length() + idx]
  } else {
    arr[idx]
  }
}

///|
fn[T] BPArray::op_set(self : BPArray[T], idx : Int, elem : T) -> Unit {
  let BPArray(arr) = self
  if idx < 0 {
    arr[arr.length() + idx] = elem
  } else {
    arr[idx] = elem
  }
}
```

Now we can start writing the search function. Before searching for the complete path, let's start with our first goal to find the length of the shortest path (equal to the search depth). Here is the basic framework:

<!-- MANUAL CHECK -->
```moonbit
fn shortest_edit(old~ : Array[Line], new~ : Array[Line]) -> Int {
  let n = old.length()
  let m = new.length()
  let max = n + m
  let v = BPArray::make(2 * max + 1, 0)
  for d = 0; d < max + 1; d = d + 1 {
    for k = -d; k < d + 1; k = k + 2 {
    ......
    }
  }
}
```

In the most extreme case (the two texts have no matching lines), it can be inferred that the maximum number of steps needed is `n + m`, and the minimum is 0. Therefore, set the variable `max = n + m`. The array `v` uses `k` as an index to store the historical record of `x` values. Since `k` ranges from `[-d, d]`, the size of this array is set to `2 * max + 1`.

But even at this point, it is still difficult to figure out what to do next, so let's only consider the case `d = 0; k = 0` for now. At this point, it must be at `(0, 0)`. Also, if the beginnings of the two texts are the same, they can be skipped directly. We write the final coordinates of this round into the array `v`.

<!-- MANUAL CHECK -->
```moonbit
if d == 0 { // When d equals 0, k must also equal 0
  x = 0
  y = x - k
  while x < n && y < m && old[x].text == new[y].text {
    // Skip all matching lines
    x = x + 1
    y = y + 1
  }
  v[k] = x
}
```

When `d > 0`, the coordinate information stored from the previous round is required. When we know the `k` value of a point and the coordinates of the points from the previous round of searching, the value of `v[k]` is easy to deduce. Because with each step k can only increase or decrease by one, `v[k]` in the search tree must extend from either `v[k - 1]` or `v[k + 1]`. The next question is: how to choose between the two paths ending at `v[k - 1]` and `v[k + 1]`?

There are two boundary cases: `k == -d` and `k == d`.

- When `k == -d`, you can only choose `v[k + 1]`.
- When `k == d`, you can only choose `v[k - 1]`.

Recalling the requirement mentioned earlier: arranging deletions before insertions as much as possible, this essentially means choosing the position with the largest `x` value from the previous position.

<!-- MANUAL CHECK -->
```moonbit
if k == -d {
  x = v[k + 1]
} else if k == d {
  x = v[k - 1] + 1 // add 1 to move horizontally
} else if v[k - 1] < v[k + 1] {
  x = v[k + 1]
} else {
  x = v[k - 1] + 1
}
```

Merging these four branches, we get the following code:

<!-- MANUAL CHECK -->
```moonbit
if k == -d || (k != d && v[k - 1] < v[k + 1]) {
  x = v[k + 1]
} else {
  x = v[k - 1] + 1
}
```

Combining all the steps above, we get the following code:

```moonbit
///
fn shortest_edit(old~ : Array[Line], new~ : Array[Line]) -> Int {
  let n = old.length()
  let m = new.length()
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
      while x < n && y < m && old[x].text == new[y].text {
        // Skip all matching lines
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

Since the initial value of the array is 0, we can omit the branch for `d == 0`.

## Epilogue

We have implemented an incomplete version of Myers' algorithm, which completes the forward path search. In the next article, we will implement the backtracking to restore the complete edit path and write a function to output a colored diff.

This article references:

- [https://blog.jcoglan.com/2017/02/15/the-myers-diff-algorithm-part-2/](https://blog.jcoglan.com/2017/02/15/the-myers-diff-algorithm-part-2/)

Thanks to the author James Coglan.
