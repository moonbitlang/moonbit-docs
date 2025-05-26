// start shortest_edit definition
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
// end shortest_edit definition

test "shortest_edit" {
  let old = lines("aaa\naaa\naaa")
  let new = lines("bbb\nbbb\nbbb")
  inspect!(shortest_edit(old~, new~), content="6")
  let old = lines("A\nB\nC\nA\nB\nB\nA")
  let new = lines("C\nB\nA\nB\nA\nC")
  inspect!(shortest_edit(old~, new~), content="5")
}