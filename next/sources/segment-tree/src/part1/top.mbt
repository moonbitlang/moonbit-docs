// start node definition
enum Node {
  Nil
  Node(Int, Node, Node)
}
// end node definition

impl ToJson for Node with to_json(self) {
  match self {
    Nil => "Nil"
    Node(value, left, right) => {
      let left_json = left.to_json()
      let right_json = right.to_json()
      [Json::number(value.to_double()), left_json, right_json]
    }
  }
}

// start op_add definition
impl Add for Node with op_add(self : Node, v : Node) -> Node {
  match (self, v) {
    (Node(left, _, _), Node(right, _, _)) => Node(left + right, self, v)
    (Node(_), Nil) => self
    (Nil, Node(_)) => v
    (Nil, Nil) => Nil
  }
}
// end op_add definition

// start build definition
fn build(data : ArrayView[Int]) -> Node {
  if data.length() == 1 {
    Node(data[0], Nil, Nil)
  } else {
    let mid = (data.length() + 1) >> 1
    build(data[0:mid]) + build(data[mid:])
  }
}
// end build definition

// start build test
test {
  let tree = build([1, 2, 3, 4, 5][:])
  @json.inspect!(tree, content=[
    15,
    [6, [3, [1, "Nil", "Nil"], [2, "Nil", "Nil"]], [3, "Nil", "Nil"]],
    [9, [4, "Nil", "Nil"], [5, "Nil", "Nil"]],
  ])
}
// end build test

// start query definition
let empty_node : Node = Node(0, Nil, Nil)

fn query(self : Node, l : Int, r : Int, query_l : Int, query_r : Int) -> Node {
  if query_l > r || l > query_r {
    empty_node
  } else if query_l <= l && query_r >= r {
    self
  } else {
    guard self is Node(_, left, right)
    let mid = (l + r) >> 1
    left.query(l, mid, query_l, query_r) +
    right.query(mid + 1, r, query_l, query_r)
  }
}
// end query definition

// start query test

test {
  let tree = build([1, 2, 3, 4, 5][:])
  let sum = match tree.query(1, 5, 1, 3) {
    Node(sum, _, _) => sum
    _ => fail!("Expected Node")
  }
  inspect!(sum, content="6")
}
// end query test
