fn min(a : Int, b : Int) -> Int {
  if a > b {
    return b
  } else {
    return a
  }
}

/// `minPathSum(triangle : Array[Array[Int]])`
///
/// Calculate the minimum path sum through a triangle of integers.
pub fn minPathSum(triangle : Array[Array[Int]]) -> Int {
  fn helper(row : Int, col : Int) -> Int {
    if row == triangle.length() {
      return 0
    }
    let next1 = helper(row + 1, col)
    let next2 = if col < row {
      helper(row + 1, col + 1)
    } else {
      2147483647
    }
    let cur = triangle[row][col]
    return cur + min(next1, next2)
  }

  helper(0, 0)
}
