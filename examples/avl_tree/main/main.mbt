fn main {
  let mut v : @lib.T[Int] = Empty
  let iter = 30 // Create an empty AVL tree with Int type

  // Add values from 0 to iter-1 to the AVL tree
  for i = 0; i < iter; i = i + 1 {
    v = v.add(i)
  }
  let height = v.height()
  println("height of the tree: \(height)")
  v.print_tree()

  // Check values from 0 to iter-1 in the AVL tree
  for i = 0; i < iter; i = i + 1 {
    if not(v.mem(i)) {
      abort("impossible")
    }
  }

  // Remove values from 0 to iter-1 from the AVL tree
  for i = 0; i < iter; i = i + 1 {
    v = v.remove(i)
  }

  // Tree is empty, removal successful
  match v {
    Empty => println("success")
    Node(_) => println("impossible")
  }
}
