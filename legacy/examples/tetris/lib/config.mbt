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

///|
let grid_row_count = 20

///|
let grid_col_count = 10

///|
enum PIECE {
  I
  L
  J
  S
  Z
  T
  O
}

///|
pub fn PIECE::piece_shape(self : PIECE) -> Array[Array[Int]] {
  match self {
    I => [[1, 1, 1, 1]]
    L => [[0, 0, 2], [2, 2, 2]]
    J => [[3, 0, 0], [3, 3, 3]]
    S => [[0, 4, 4], [4, 4, 0]]
    Z => [[5, 5, 0], [0, 5, 5]]
    T => [[6, 6, 6], [0, 6, 0]]
    O => [[7, 7], [7, 7]]
  }
}
