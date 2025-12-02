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
enum Cell {
  Dead
  Alive
}

///|
struct Universe {
  width : Int
  height : Int
  mut cells : Array[Cell]
}

///|
fn Universe::get_index(self : Universe, row : Int, column : Int) -> Int {
  if row * self.width + column < self.width * self.height {
    row * self.width + column
  } else {
    0
  }
}

///|
pub fn new() -> Universe {
  let width = 64
  let height = 64
  let cells : Array[Cell] = Array::make(width * height, Dead)
  let mut idx = 0
  while idx < width * height {
    if idx % 2 == 0 || idx % 7 == 0 {
      cells[idx] = Alive
    } else {
      cells[idx] = Dead
    }
    idx = idx + 1
  }
  { width, height, cells }
}

///|
pub fn Universe::get_width(self : Universe) -> Int {
  self.width
}

///|
pub fn Universe::get_height(self : Universe) -> Int {
  self.height
}

///|
pub fn Universe::get_cells(self : Universe) -> Array[Cell] {
  self.cells
}

///|
pub fn Universe::get_cell(self : Universe, idx : Int) -> Int {
  match self.cells[idx] {
    Alive => 1
    Dead => 0
  }
}

///|
fn Universe::live_neighbor_count(
  self : Universe,
  row : Int,
  column : Int,
) -> Int {
  let mut count = 0
  let delta_rows = [self.height - 1, 0, 1]
  let delta_cols = [self.width - 1, 0, 1]
  let mut r = 0
  while r < 3 {
    let mut c = 0
    while c < 3 {
      if delta_rows[r] == 0 && delta_cols[c] == 0 {
        c = c + 1
        continue
      }
      let neighbor_row = (row + delta_rows[r]) % self.height
      let neighbor_col = (column + delta_cols[c]) % self.width
      let idx = self.get_index(neighbor_row, neighbor_col)
      count = count + self.get_cell(idx)
      c = c + 1
    }
    r = r + 1
  }
  count
}

///|
pub fn Universe::tick(self : Universe) -> Unit {
  let next : Array[Cell] = Array::make(self.width * self.height, Dead)
  let mut r = 0
  while r < self.height {
    let mut c = 0
    while c < self.width {
      let idx = self.get_index(r, c)
      let cell = self.cells[idx]
      let live_neighbor = self.live_neighbor_count(r, c)
      let next_cell : Cell = match (cell, live_neighbor) {
        (Alive, c) =>
          if c < 2 {
            Dead
          } else if c == 2 || c == 3 {
            Alive
          } else {
            Dead
          }
        (Dead, 3) => Alive
        _ => cell
      }
      next[idx] = next_cell
      c = c + 1
    }
    r = r + 1
  }
  self.cells = next
}

///|
pub fn Universe::to_string(self : Universe) -> String {
  let mut r = 0
  let mut cells = ""
  while r < self.height {
    let mut c = 0
    while c < self.width {
      let idx = self.get_index(r, c)
      let cell = self.cells[idx]
      // No buffer implementation?
      cells = cells +
        (match cell {
          Alive => "▅"
          Dead => "☐"
        })
      c = c + 1
    }
    cells = cells + "\n"
    r = r + 1
  }
  cells
}
