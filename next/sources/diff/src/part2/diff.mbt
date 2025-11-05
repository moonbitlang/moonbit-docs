///|
/// start shortest_edit definition
///
fn shortest_edit(
  old~ : Array[Line],
  new~ : Array[Line],
) -> Array[(BPArray[Int], Int)] {
  let n = old.length()
  let m = new.length()
  let max = n + m
  let v = BPArray::make(2 * max + 1, 0)
  let trace = []
  fn push(v : BPArray[Int], d : Int) -> Unit {
    trace.push((v, d))
  }
  // v[1] = 0
  for d = 0; d < max + 1; d = d + 1 {
    push(v.copy(), d)
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
        x = x + 1
        y = y + 1
      }
      v[k] = x
      if x >= n && y >= m {
        return trace
      }
    }
  } else {
    abort("impossible")
  }
}
// end shortest_edit definition

///|
/// start backtrack_fst definition
///
fn backtrack(
  new~ : Array[Line],
  old~ : Array[Line],
  trace : Array[(BPArray[Int], Int)],
) -> Array[Edit] {
  let mut x = old.length()
  let mut y = new.length()
  let edits = Array::new(capacity=trace.length())
  // end backtrack_fst definition
  // start backtrack_snd definition
  for i = trace.length() - 1; i >= 0; i = i - 1 {
    let (v, d) = trace[i]
    let k = x - y
    let prev_k = if k == -d || (k != d && v[k - 1] < v[k + 1]) {
      k + 1
    } else {
      k - 1
    }
    let prev_x = v[prev_k]
    let prev_y = prev_x - prev_k
    while x > prev_x && y > prev_y {
      x = x - 1
      y = y - 1
      edits.push(Equal(old=old[x], new=new[y]))
    }
    if d > 0 {
      if x == prev_x {
        edits.push(Insert(new=new[prev_y]))
      } else if y == prev_y {
        edits.push(Delete(old=old[prev_x]))
      }
      x = prev_x
      y = prev_y
    }
  }
  // end backtrack_snd definition
  return edits
}

///|
/// start diff definition
///
fn diff(old~ : Array[Line], new~ : Array[Line]) -> Array[Edit] {
  let trace = shortest_edit(old~, new~)
  backtrack(old~, new~, trace)
}
// end diff definition

///|
test "myers diff" {
  let old = lines("A\nB\nC\nA\nB\nB\nA")
  let new = lines("C\nB\nA\nB\nA\nC")
  inspect(
    pprint_diff(diff(old~, new~)),
    content=(
      #|-    1         A
      #|-    2         B
      #|     3    1    C
      #|+         2    B
      #|     4    3    A
      #|     5    4    B
      #|-    6         B
      #|     7    5    A
      #|+         6    C
      #|
    ),
  )
}
