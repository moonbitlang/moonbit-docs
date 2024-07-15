//  Copyright 2024 International Digital Economy Academy
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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
