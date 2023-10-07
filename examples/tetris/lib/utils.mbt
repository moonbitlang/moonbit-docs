pub func stream[T](self : Array[T]) -> List[T] {
  fn go(idx : Int) -> List[T] {
    if idx == self.length() {
      Nil
    } else {
      Cons(self[idx], go(idx + 1))
    }
  }

  go(0)
}

pub func length[T](self : List[T]) -> Int {
  match self {
    Nil => 0
    Cons(_, n) => 1 + n.length()
  }
}

pub func check_collision(grid : List[Array[Int]], shap : Array[Array[Int]],
        offset : (Int, Int)) -> Bool {
  let len_r = shap.length()
  let len_c = shap[0].length()
  if offset.1 + len_r > grid_row_count {
    return true
  }
  fn go(l : List[Array[Int]], r : Int) -> Bool {
    match l {
      Cons(v, n) => {
        if r < offset.1 {
          return go(n, r + 1)
        }
        if r >= offset.1 + len_r {
          return false
        }
        var c = 0
        while c < len_c {
          if shap[r - offset.1][c] == 0 {
            c = c + 1
            continue
          }
          if v[c + offset.0] != 0 {
            return true
          }
          c = c + 1
        }
        return go(n, r + 1)
      }
      Nil => false
    }
  }

  return go(grid, 0)
}

pub let int_max = 2147483647

pub func max[T : Compare](a : T, b : T) -> T {
  if a.compare(b) >= 0 {
    return a
  }
  return b
}

pub func min[T : Compare](a : T, b : T) -> T {
  if a.compare(b) >= 0 {
    return b
  }
  return a
}

pub func contain(ary : Array[Int], t : Int) -> Bool {
  var i = 0
  while i < ary.length() {
    if ary[i] == t {
      return true
    }
    i = i + 1
  }
  false
}

pub func get_effective_height(grid : List[Array[Int]], shap : Array[Array[Int]],
        offset : (Int, Int)) -> Int {
  let x = offset.0
  var y = offset.1
  while check_collision(grid, shap, (x, y)) == false {
    y = y + 1
  }
  y - 1
}

