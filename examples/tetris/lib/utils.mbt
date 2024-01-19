pub fn stream[T](now : Array[T]) -> List[T] {
  fn go(idx : Int) -> List[T] {
    if idx == now.length() {
      Nil
    } else {
      Cons(now[idx], go(idx + 1))
    }
  }

  go(0)
}

pub fn length[T](now : List[T]) -> Int {
  match now {
    Nil => 0
    Cons(_, n) => 1 + length(n)
  }
}

pub fn check_collision(grid : List[Array[Int]], shap : Array[Array[Int]],
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
        let mut c = 0
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

pub fn max[T : Compare](a : T, b : T) -> T {
  if a.compare(b) >= 0 {
    return a
  }
  return b
}

pub fn min[T : Compare](a : T, b : T) -> T {
  if a.compare(b) >= 0 {
    return b
  }
  return a
}

pub fn contain(ary : Array[Int], t : Int) -> Bool {
  let mut i = 0
  while i < ary.length() {
    if ary[i] == t {
      return true
    }
    i = i + 1
  }
  false
}

pub fn get_effective_height(grid : List[Array[Int]], shap : Array[Array[Int]],
        offset : (Int, Int)) -> Int {
  let x = offset.0
  let mut y = offset.1
  while check_collision(grid, shap, (x, y)) == false {
    y = y + 1
  }
  y - 1
}

