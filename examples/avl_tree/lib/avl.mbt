// https://en.wikipedia.org/wiki/AVL_tree
// https://zhuanlan.zhihu.com/p/430867594

// Empty represents an empty node in the AVL tree
// Node represents a node in the AVL tree with left child, value, right child, and height
pub enum T[U] {
  Empty
  Node (T[U], U, T[U], Int)
}

/// Calculate the height of a tree-like structure using pattern matching.
///
/// This function calculates the height of a tree-like structure represented by the
/// user-defined enum 'T[U]' using pattern matching. The height of an empty tree is 0,
/// and the height of a non-empty tree node is determined by its stored height value.
///
/// @param {T[U]} self - A user-defined enum representing the tree-like structure.
/// @return {Int} The height of the tree-like structure.
pub func height[U](self: T[U]) -> Int {
  match self {
    Empty => 0
    Node(_, _, _, h) => h
  }
}

/// Create a new node with the given left and right subtrees, along with a value of type 'U'.
///
/// This function constructs a new node of the user-defined enum type 'T[U]' using the provided left subtree 'l',
/// value 'v', and right subtree 'r'. The height of the node is determined by the maximum height between
/// the left and right subtrees, incremented by one.
///
/// @param {T[U]} l - The left subtree of the node.
/// @param {U} v - The value to be stored in the node.
/// @param {T[U]} r - The right subtree of the node.
/// @return {T[U]} - A new node of type 'T[U]' with the specified left subtree, value, and right subtree.
func create[U](l: T[U], v: U, r: T[U]) -> T[U] {
  let hl = l.height()
  let hr = r.height()
  Node(l, v, r, if hl >= hr { hl + 1 } else { hr + 1 })
}

/// Perform balancing operation on a avl tree node.
///
/// This function performs a balancing operation on a avl tree node based on the heights
/// of its left and right subtrees. It ensures that the heights of the subtrees are balanced
/// and returns a new avl tree node with appropriate restructuring if necessary.
///
/// @param {T[U]} l - The left subtree of the node.
/// @param {U} v - The value of the node.
/// @param {T[U]} r - The right subtree of the node.
/// @return {T[U]} - A new avl tree node after balancing.
func bal[U](l: T[U], v: U, r: T[U]) -> T[U] {
  let hl = l.height()
  let hr = r.height()

  // Left subtree is taller by more than 2 level
  if hl > hr + 2 {
    match l {
      Empty =>
        Empty // impossible
      Node(ll, lv, lr, _) =>
        if ll.height() >= lr.height() {
          create(ll, lv, create(lr, v, r))
        } else {
          match lr {
            Empty =>
              Empty // impossible
            Node(lrl, lrv, lrr, _) =>
              create(create(ll, lv, lrl), lrv, create(lrr, v, r))
          }
        }
    }
  } else if hr > hl + 2 {
    // Right subtree is taller by more than 2 level
    match r {
      Empty =>
        Empty // impossible
      Node(rl, rv, rr, _) =>
        if rr.height() >= rl.height() {
          create(create(l, v, rl), rv, rr)
        } else {
          match rl {
            Empty =>
              Empty // impossible
            Node(rll, rlv, rlr, _) =>
              create(create(l, v, rll), rlv, create(rlr, rv, rr))
          }
        }
    }
  } else {
    Node(l, v, r, if hl >= hr { hl + 1 } else { hr + 1 })
  }
}

/// Adds a value to a tree node and performs balancing.
///
/// This function adds a value 'x' to the given tree node 'self' of type 'T[U]'. The tree
/// node is expected to be of an enumerated type 'T', and the value type 'U' should implement
/// the 'Compare' interface for comparison.
///
/// @param {T[U]} self - The tree node of type 'T[U]' to which the value will be added.
/// @param {U} x - The value of type 'U' to be added to the tree node.
/// @return {T[U]} A balanced tree node of type 'T[U]' after adding the value.
pub func add[U:Compare](self: T[U], x: U) -> T[U] {
  match self {
    Empty => Node(Empty, x, Empty, 1)
    Node(l, v, r, _) as t => {
      let c = x.compare(v)
      if c == 0 {
        t
      } else if c < 0 { bal(l.add(x), v, r) } else { bal(l, v, r.add(x)) }
    }
  }
}

/// Find the minimum element in a tree-like data structure.
///
/// This function operates on a tree-like data structure of type 'T[U]', where 'U' is a type parameter representing
/// the element type. The function recursively
/// navigates the tree using pattern matching to find the minimum element.
///
/// @param {T[U]} 'self' - The tree-like data structure on which to find the minimum element.
/// @param {U} 'default' - The default value to return if the tree is empty.
/// @return {U} The minimum element found in the tree, or the 'default' value if the tree is empty.
func min_elt[U](self: T[U], default: U) -> U {
  match self {
    Empty => default
    Node(Empty, v, _, _) => v
    Node(l, v, _, _) => l.min_elt(v)
  }
}

/// Remove the minimum element from a avl tree and rebalance the tree.
///
/// This function takes a avl tree 'l' of type 'T[U]', an element 'v' of type 'U' to be removed,
/// and another avl tree 'r' of type 'T[U]'. It removes the minimum element from the tree 'l',
/// and then rebalances the resulting tree using the 'bal' function.
///
/// @param {T[U]} l - A avl tree from which the minimum element is to be removed.
/// @param {U} v - An element of type 'U' to be removed from the tree.
/// @param {T[U]} r - Another avl tree to be combined with the modified 'l' after removal.
/// @return {T[U]} A avl tree resulting from the removal of the minimum element and rebalancing.
func remove_min_elt[U](l: T[U], v: U, r: T[U]) -> T[U] {
  match l {
    Empty => r
    Node(ll, lv, lr, _) => bal(remove_min_elt(ll, lv, lr), v, r)
  }
}

/// Merge two AVL trees of the same user-defined type 'U' into a new AVL tree.
///
/// This function takes two AVL trees 'self' and 'other' of type 'T[U]' and merges them into a new AVL tree.
/// The result of the merge is a balanced AVL tree that contains all the elements from both input trees while
/// maintaining the AVL tree properties.
///
/// @param {T[U]} self - The first AVL tree to merge.
/// @param {T[U]} other - The second AVL tree to merge.
/// @return {T[U]} A new AVL tree containing elements from both input trees, balanced to maintain AVL properties.
func internal_merge[U](self: T[U], other: T[U]) -> T[U] {
  match (self, other) {
    (Empty, t) => t
    (t, Empty) => t
    (_, Node(rl, rv, rr, _)) =>
      bal(self, other.min_elt(rv), remove_min_elt(rl, rv, rr))
  }
}

/// Removes a value from the AVL tree while maintaining balance.
///
/// This function removes a value from the AVL tree while ensuring that the resulting tree
/// remains balanced according to the AVL tree balancing rules. The type 'U' represents
/// the type of values in the tree and must implement the 'Compare' interface for comparison.
///
/// @param {T[U]} self - The AVL tree from which to remove the value.
/// @param {U} x - The value to be removed from the AVL tree.
/// @return {T[U]} - A new AVL tree with the specified value removed, maintaining balance.
pub func remove[U:Compare](self: T[U], x: U) -> T[U] {
  match self {
    Empty => Empty
    Node(l, v, r, _) => {
      let c = x.compare(v)
      if c == 0 {
        l.internal_merge(r)
      } else if c < 0 { bal(l.remove(x), v, r) } else { bal(l, v, r.remove(x)) }
    }
  }
}

/// Repeat a given string a specified number of times.
///
/// This function takes a string 's' and an integer 'n' as input and returns a new string
/// containing the original string repeated 'n' times.
///
/// @param {String} s - The string to be repeated.
/// @param {Int} n - The number of times to repeat the string.
/// @return {String} A new string containing 's' repeated 'n' times.
func repeat_str(s: String, n: Int) -> String {
  var result = ""
  var i = 0
  while i < n {
    result = result + s
    i = i + 1
  }
  result
}

/// Print the AVL tree
///
/// This function prints the AVL tree by traversing it in an in-order manner and displaying
/// the nodes at each level with appropriate indentation.
///
/// The value type 'U' should implement the 'to_string' interface for 'Show'.
///
/// @param {T[U]} self - The AVL tree to be printed.
pub func print_tree[U:Show](self: T[U]) {
  fn helper(node: T[U], level: Int) {
    match node {
      Empty => ()
      Node(l, v, r, _) => {
        helper(l, level + 1)
        let indent = repeat_str("  ", level)
        (indent + v.to_string()).print()
        helper(r, level + 1)
      }
    }
    "\n".print()
  }
  helper(self, 0)
}

/// Check if a given element exists in an AVL tree.
///
/// This function checks whether a specified element 'x' exists in the AVL tree.
/// Type 'U' must implement the 'Compare' interface. The function
/// recursively searches the tree's nodes for the given element.
///
/// @param {T[U]} self - An AVL tree of type 'T' with elements of type 'U'.
/// @param {U} x - The element to search for in the AVL tree.
/// @return {Bool} - 'true' if the element exists in the tree, 'false' otherwise.
pub func mem[U:Compare](self: T[U], x: U) -> Bool {
  match self {
    Empty => false
    Node(l, v, r, _) => {
      let c = x.compare(v)
      let tree = if c < 0 { l } else { r }
      c == 0 || tree.mem(x)
    }
  }
}

