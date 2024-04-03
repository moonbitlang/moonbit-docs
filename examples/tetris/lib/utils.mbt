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

pub fn get_effective_height(grid : List[Array[Int]], shap : Array[Array[Int]],
        offset : (Int, Int)) -> Int {
  let x = offset.0
  let mut y = offset.1
  while check_collision(grid, shap, (x, y)) == false {
    y = y + 1
  }
  y - 1
}

