func min(a : Int, b : Int) -> Int {
  if a > b {
    return b
  } else {
    return a
  }
}

/// Calculate the minimum path sum through a triangle of integers.
///
/// Given a triangle represented as a list of lists of integers, where each list
/// corresponds to a row of the triangle, this function calculates the minimum
/// path sum from the top to the bottom of the triangle by moving only to adjacent
/// numbers on the row below.
///
/// @param {Array[Array[Int]]} triangle - A 2D array representing the triangle of integers.
/// @return {Int} - The minimum path sum through the triangle.
///
/// The function uses a recursive approach with dynamic programming to calculate
/// the minimum path sum. It starts from the top of the triangle and recursively
/// calculates the minimum path sum for each possible path from the current position
/// to the bottom row. The `helper` function is used for the recursive calculation.
pub func minPathSum(triangle : Array[Array[Int]]) -> Int {
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
