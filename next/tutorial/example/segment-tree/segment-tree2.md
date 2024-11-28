# Segment Trees (Part 2)

## Introduction

In the previous article, we discussed the basic implementation of a segment tree. That tree only allowed range queries (single-point modifications and queries were also possible), but it couldn't handle range modifications, such as adding a value to all elements in a given range.

In this session, we will deepen the abstraction by introducing the concept of **LazyTag** to handle range modifications, creating a more functional segment tree.

## How to Implement Range Modifications?

First, let's imagine what happens if we add a number to all elements in a range on the segment tree. How would we do this using a straightforward approach?

![add to segment tree](/imgs/segment-tree-add.png)

Take the segment tree from the last lesson as an example. In the figure below, we add 1 to the range [4, 7]. You'll notice that we need to rebuild and maintain all parts of the tree that cover this range, which is too costly.

Is there a better way? Of course! We can use **LazyTag**.

![lazytag](/imgs/segment-tree-lazytag.png)

Consider that instead of modifying every affected part, we mark the smallest covering range with a "+1" tag. Based on the length of the range, we calculate its value and merge it upward. Following the complexity of querying from the last lesson, this operation would be O(log N).

However, there's a problem. While querying ranges like [1, 7] or [4, 7] works fine, what if we query [4, 6]? The minimal covering ranges are [4, 5] and [6, 6], not [4, 7], so our tag doesn't propagate to lower nodes.

Here’s where the **Lazy** aspect of LazyTag comes into play.

![add using lazytag](/imgs/segment-tree-add-lazytag.png)

We define that when querying a node with a tag, the tag is distributed to its child nodes. These child nodes inherit the tag and compute their values based on their length. The following diagram shows the propagation of the tag downward when querying [4, 6].

This "lazy propagation" ensures that each modification is completed in \(O(\log N)\), while ensuring correct query results.

**Note:** Some may wonder about overlapping tags. However, additive tags like these merge seamlessly without affecting the total sum of a node.

Let’s dive into the code!

## Implementation

### Before We Begin

In the last lesson, when using the `let` to destructure `Node`, we could be sure that the enum being destructured wasn’t `Nil`. However, the compiler couldn't guarantee this, so we received a warning for using:

```moonbit
let Node(x, y) = z
```

Although it didn’t affect execution, it was somewhat misleading. With MoonBit’s newly introduced `guard` statement, we can now handle this better using:

```moonbit
guard let Node(x, y) = z
```

### Basic Definitions

In the previous code, we defined the segment tree using `enum`. However, none of the elements were clearly named, which was manageable when the data size was small. Now, we need to add **Tag** and **Length** attributes, so it makes sense to use labeled arguments in the `enum` definition:

```moonbit
enum Data {
  Data(~sum: Int, ~len: Int)
} derive(Show)

enum LazyTag {
  Nil
  Tag(Int)
} derive(Show)

enum Node {
  Nil
  Node(~data: Data, ~tag: LazyTag, ~left: Node, ~right: Node)
} derive(Show)
```

This allows for clearer initialization and pattern matching, making the code easier to follow. We've also abstracted the `Data` type, adding a `len` attribute to represent the length of the current range, which is useful for calculating the node's value.

### Tree Construction

Similar to the last lesson, before building the tree, we need to define the addition operations between `Node` types. However, since we’ve abstracted `Data`, we must account for its addition too:

```moonbit
fn op_add(self: Data, v: Data) -> Data {
  match (self, v) {
    (Data(sum=a, len=len_a), Data(sum=b, len=len_b)) =>
      Data(sum=a + b, len=len_a + len_b)
  }
}

fn op_add(self: Node, v: Node) -> Node {
  match (self, v) {
    (Node(data=l, ..), Node(data=r, ..)) =>
      Node(data=l + r, tag=Nil, left=self, right=v)
    (Node(_), Nil) => self
    (Nil, Node(_)) => v
    (Nil, Nil) => Nil
  }
}
```

Here, we’ve ignored merging LazyTags for now and set the resulting tag to `Nil` because once a node is reached, its parent’s LazyTag no longer applies.

Now, we can implement the tree-building function:

```moonbit
fn build(data: ArrayView[Int]) -> Node {
  if data.length() == 1 {
    Node(data=Data(sum=data[0], len=1), tag=Nil, left=Nil, right=Nil)
  } else {
    let mid = (data.length() + 1) >> 1
    build(data[0:mid]) + build(data[mid:])
  }
}
```

### LazyTag and Range Modifications

A node receiving a LazyTag is handled by the `apply` function. The key logic here is how the tag is merged and how the value is computed based on the node’s length:

```moonbit
fn op_add(self: LazyTag, v: LazyTag) -> LazyTag {
  match (self, v) {
    (Tag(a), Tag(b)) => Tag(a + b)
    (Nil, t) | (t, Nil) => t
  }
}

fn apply(self: Node, v: LazyTag) -> Node {
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

This code allows a node to compute its value based on its range length and the applied LazyTag. It also merges existing tags correctly.

Next, we implement range modifications:

```moonbit
fn modify(
  self: Node,
  l: Int,
  r: Int,
  modify_l: Int,
  modify_r: Int,
  tag: LazyTag
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

The logic is similar to the query function from the previous lesson, but now each relevant node applies the necessary LazyTag for the modification.

Interestingly, even with range modifications, this segment tree remains persistent (immutable). The `modify` function returns a new tree without altering the original, reflecting the recursive and functional nature of the code. Since MoonBit uses garbage collection, there’s no need for explicit pointers, unlike in Rust.

### Queries

For queries, we need to remember to push the LazyTag downwards:

```moonbit
let empty_node: Node = Node(
  data=Data(sum=0, len=0),
  tag=Nil,
  left=Nil,
  right=Nil,
)

fn query(self: Node, l: Int, r: Int, query_l: Int, query_r: Int) -> Node {
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

## Conclusion

With this, we have a segment tree that supports range modifications and is much more functional!

In the next lesson, we’ll add multiplication support to the segment tree and explore some use cases for immutable segment trees. Stay tuned!

Full code is available [here](https://github.com/moonbit-community/MoonBit-SegmentTree/blob/main/2/main.mbt).
