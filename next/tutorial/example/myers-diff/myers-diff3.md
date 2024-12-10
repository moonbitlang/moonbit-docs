# Myers diff 3

This article is the third in the [diff series](https://docs.moonbitlang.com/examples/myers-diff). In the [previous part](https://docs.moonbitlang.com/examples/myers-diff2), we explored the full Myers algorithm and its limitations. In this post, we'll learn how to implement a variant of the Myers algorithm that operates with linear space complexity.

## Divide and Conquer

The linear variant of Myers' diff algorithm used by Git employs a concept called the _Snake_ (sometimes referred to as the _Middle Snake_) to break down the entire search process. A Snake in the edit graph represents a diagonal movement of 0 to N steps after a single left or down move. The linear Myers algorithm finds the middle Snake on the optimal edit path and uses it to divide the entire edit graph into two parts. The subsequent steps apply the same technique to the resulting subgraphs, eventually producing a complete edit path.

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

When searching from the bottom-right, the diagonal coordinate can no longer be referred to as _k_. We need to define a new diagonal coordinate **c = k - delta**. This coordinate is the mirror image of _k_, perfectly suited for reverse direction search.

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

How do we determine if the searches overlap? Simply check if the position on a diagonal line in the forward search has an _x_ value greater than that in the reverse search. However, since the _k_ and _c_ coordinates differ for the same diagonal, the conversion can be a bit tricky.

### Code Implementation

We'll start by defining `Snake` and `Box` types, representing the middle snake and the sub-edit graphs (since they're square, we call them `Box`).

```{literalinclude} /sources/diff/src/part3/diff.mbt
:language: moonbit
:start-after: start box definition
:end-before: end box definition
```

To avoid getting bogged down in details too early, let's assume we already have a function `midpoint : (Box, Array[Line], Array[Line]) -> Snake?` to find the middle snake. Then, we can build the function `find_path` to search for the complete path.

```{literalinclude} /sources/diff/src/part3/diff.mbt
:language: moonbit
:start-after: start findpath definition
:end-before: end findpath definition
```

The implementation of `find_path` is straightforward, but `midpoint` is a bit more complex:

- For a `Box` of size 0, return `None`.
- Calculate the search boundaries. Since forward and backward searches each cover half the distance, divide by two. However, if the size of the `Box` is odd, add one more to the forward search boundary.
- Store the results of the forward and backward searches in two arrays.
- Alternate between forward and backward searches, returning `None` if no result is found.

```{literalinclude} /sources/diff/src/part3/diff.mbt
:language: moonbit
:start-after: start midpoint definition
:end-before: end midpoint definition
```

The forward and backward searches have some modifications compared to the original Myers algorithm, which need a bit of explanation:

- Since we need to return the snake, the search process must calculate the previous coordinate (`px` stands for previous x).
- The search now works within a `Box` (not the global edit graph), so calculating `y` from `x` (or vice versa) requires conversion.
- The backward search minimizes `y` as a heuristic strategy, but minimizing `x` would also work.

```{literalinclude} /sources/diff/src/part3/diff.mbt
:language: moonbit
:start-after: start search definition
:end-before: end search definition
```

## Conclusion

In addition to the default diff algorithm, Git also offers another diff algorithm called patience diff. It differs significantly from Myers diff in approach and sometimes produces more readable diff results.
