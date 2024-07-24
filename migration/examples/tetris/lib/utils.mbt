//  Copyright 2023 luoxuwei
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

pub fn check_collision(
  grid : @immut/list.List[Array[Int]],
  shap : Array[Array[Int]],
  offset : (Int, Int)
) -> Bool {
  let len_r = shap.length()
  let len_c = shap[0].length()
  if offset.1 + len_r > grid_row_count {
    return true
  }
  loop grid, 0 {
    Cons(v, n), r => {
      if r < offset.1 {
        continue n, r + 1
      }
      if r >= offset.1 + len_r {
        return false
      }
      for c = 0; c < len_c; c = c + 1 {
        if shap[r - offset.1][c] == 0 {
          continue c + 1
        }
        if v[c + offset.0] != 0 {
          return true
        }
      }
      continue n, r + 1
    }
    Nil, _ => false
  }
}

pub fn get_effective_height(
  grid : @immut/list.List[Array[Int]],
  shap : Array[Array[Int]],
  offset : (Int, Int)
) -> Int {
  let x = offset.0
  let mut y = offset.1
  while check_collision(grid, shap, (x, y)) == false {
    y = y + 1
  }
  y - 1
}
