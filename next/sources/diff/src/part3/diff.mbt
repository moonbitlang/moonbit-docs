///| start box definition
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

// end box definition
///|
fn is_odd(n : Int) -> Bool {
  (n & 1) == 1
}

///|
fn is_even(n : Int) -> Bool {
  (n & 1) == 0
}

// start search definition
///|
fn Box::forward(
  self : Self,
  forward~ : BPArray[Int],
  backward~ : BPArray[Int],
  depth : Int,
  old~ : Array[Line],
  new~ : Array[Line]
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
  new~ : Array[Line]
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
// end search definition

// start midpoint definition
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
// end midpoint definition

///| start findpath definition
///
fn Box::find_path(
  box : Self,
  old~ : Array[Line],
  new~ : Array[Line]
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
  let head = headbox.find_path(old~, new~).or(Iter::singleton(start))
  let tail = tailbox.find_path(old~, new~).or(Iter::singleton(end))
  Some(head.concat(tail))
}
// end findpath definition

///|
fn linear_diff(old~ : Array[Line], new~ : Array[Line]) -> Array[Edit]? {
  let initial_box = Box::{
    left: 0,
    top: 0,
    right: old.length(),
    bottom: new.length(),
  }
  guard initial_box.find_path(old~, new~) is Some(path) else { None }
  // path length >= 2
  let xy = path.take(1).collect()[0] // (0, 0)
  let mut x1 = xy.0
  let mut y1 = xy.1
  let edits = Array::new(capacity=old.length() + new.length())
  path
  .drop(1)
  .each(fn(xy) {
    let x2 = xy.0
    let y2 = xy.1
    while x1 < x2 && y1 < y2 && old[x1].text == new[y1].text {
      edits.push(Equal(old=old[x1], new=new[y1]))
      x1 = x1 + 1
      y1 = y1 + 1
    }
    if x2 - x1 < y2 - y1 {
      edits.push(Insert(new=new[y1]))
      y1 += 1
    }
    if x2 - x1 > y2 - y1 {
      edits.push(Delete(old=old[x1]))
      x1 += 1
    }
    while x1 < x2 && y1 < y2 && old[x1].text == new[y1].text {
      edits.push(Equal(old=old[x1], new=new[y1]))
      x1 = x1 + 1
      y1 = y1 + 1
    }
    x1 = x2
    y1 = y2
  })
  return Some(edits)
}

///|
test "myers diff" {
  let old = lines("A\nB\nC\nA\nB\nB\nA")
  let new = lines("C\nB\nA\nB\nA\nC")
  let r = linear_diff(old~, new~).unwrap()
  inspect(
    pprint_diff(r),
    content=
      #|-    1         A
      #|-    2         B
      #|     3    1    C
      #|-    4         A
      #|     5    2    B
      #|+         3    A
      #|     6    4    B
      #|     7    5    A
      #|+         6    C
      #|
    ,
  )
}
