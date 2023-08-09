func init {
  var v : @lib.T[Int] = Empty // Create an empty AVL tree with Int type
  let iter = 30

  // Add values from 0 to iter-1 to the AVL tree
  var i = 0
  while i < iter {
    v = v.add(i)
    i = i + 1
  }

  let height = v.height()
  "height of the tree: \(height)".print()

  v.print_tree()

  // Check values from 0 to iter-1 in the AVL tree
  var j = 0
  while j < iter {
    if not(v.mem(j)) {
      "impossible".print()
    }
    j = j + 1
  }

  // Remove values from 0 to iter-1 from the AVL tree
  var k = 0
  while k < iter {
    v = v.remove(k)
    k = k + 1
  }

  "\n".print()

  // Tree is empty, removal successful
  match v {
    Empty => "success".print()
    Node(_) => "impossible".print()
  }
}

