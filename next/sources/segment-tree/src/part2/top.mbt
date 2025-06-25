// start data definition
///|
enum Data {
  Data(sum~ : Int, len~ : Int)
}

///|
enum LazyTag {
  Nil
  Tag(Int)
}

///|
enum Node {
  Nil
  Node(data~ : Data, tag~ : LazyTag, left~ : Node, right~ : Node)
}
// end data definition

///|
impl ToJson for Data with to_json(data) {
  let Data(sum~, len~) = data
  [Json::number(sum.to_double()), Json::number(len.to_double())]
}

///|
impl ToJson for LazyTag with to_json(tag) {
  match tag {
    Nil => "Nil"
    Tag(value) => Json::number(value.to_double())
  }
}

///|
impl ToJson for Node with to_json(node) {
  match node {
    Nil => "Nil"
    Node(data~, tag~, left~, right~) => {
      let data_json = data.to_json()
      let tag_json = tag.to_json()
      let left_json = left.to_json()
      let right_json = right.to_json()
      {
        "data": data_json,
        "tag": tag_json,
        "left": left_json,
        "right": right_json,
      }
    }
  }
}

// start op_add definition
///|
impl Add for Data with op_add(self : Data, v : Data) -> Data {
  match (self, v) {
    (Data(sum=a, len=len_a), Data(sum=b, len=len_b)) =>
      Data(sum=a + b, len=len_a + len_b)
  }
}

///|
impl Add for Node with op_add(self : Node, v : Node) -> Node {
  match (self, v) {
    (Node(data=l, ..), Node(data=r, ..)) =>
      Node(data=l + r, tag=Nil, left=self, right=v)
    (Node(_), Nil) => self
    (Nil, Node(_)) => v
    (Nil, Nil) => Nil
  }
}
// end op_add definition

// start lazytag definition
///|
impl Add for LazyTag with op_add(self : LazyTag, v : LazyTag) -> LazyTag {
  match (self, v) {
    (Tag(a), Tag(b)) => Tag(a + b)
    (Nil, t) | (t, Nil) => t
  }
}

///|
fn apply(self : Node, v : LazyTag) -> Node {
  match (self, v) {
    (Node(data=Data(sum=a, len=length), tag~, left~, right~), Tag(v) as new_tag) =>
      Node(
        data=Data(sum=a + v * length, len=length),
        tag=tag + new_tag,
        left~,
        right~,
      )
    (_, Nil) => self
    (Nil, _) => Nil
  }
}
// end lazytag definition

// start build definition
///|
fn build(data : ArrayView[Int]) -> Node {
  if data.length() == 1 {
    Node(data=Data(sum=data[0], len=1), tag=Nil, left=Nil, right=Nil)
  } else {
    let mid = (data.length() + 1) >> 1
    build(data[0:mid]) + build(data[mid:])
  }
}
// end build definition

// start modify definition
///|
fn modify(
  self : Node,
  l : Int,
  r : Int,
  modify_l : Int,
  modify_r : Int,
  tag : LazyTag
) -> Node {
  if modify_l > r || l > modify_r {
    self
  } else if modify_l <= l && modify_r >= r {
    self.apply(tag)
  } else {
    guard self is Node(left~, right~, ..)
    let mid = (l + r) >> 1
    left.modify(l, mid, modify_l, modify_r, tag) +
    right.modify(mid + 1, r, modify_l, modify_r, tag)
  }
}
// end modify definition

// start query definition
///|
let empty_node : Node = Node(
  data=Data(sum=0, len=0),
  tag=Nil,
  left=Nil,
  right=Nil,
)

///|
fn query(self : Node, l : Int, r : Int, query_l : Int, query_r : Int) -> Node {
  if query_l > r || l > query_r {
    empty_node
  } else if query_l <= l && query_r >= r {
    self
  } else {
    guard self is Node(tag~, left~, right~, ..)
    let mid = (l + r) >> 1
    left.apply(tag).query(l, mid, query_l, query_r) +
    right.apply(tag).query(mid + 1, r, query_l, query_r)
  }
}
// end query definition

///|
test {
  let tree = build([1, 2, 3, 4, 5][:])
  @json.inspect(tree.modify(1, 5, 1, 3, Tag(1)).query(1, 5, 1, 3), content={
    "data": [9, 3],
    "tag": "Nil",
    "left": {
      "data": [9, 3],
      "tag": 1,
      "left": {
        "data": [3, 2],
        "tag": "Nil",
        "left": { "data": [1, 1], "tag": "Nil", "left": "Nil", "right": "Nil" },
        "right": { "data": [2, 1], "tag": "Nil", "left": "Nil", "right": "Nil" },
      },
      "right": { "data": [3, 1], "tag": "Nil", "left": "Nil", "right": "Nil" },
    },
    "right": { "data": [0, 0], "tag": "Nil", "left": "Nil", "right": "Nil" },
  })
}
