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

struct Tetris {
  mut dead : Bool
  mut grid : @immut/list.List[Array[Int]]
  mut piece_pool : @immut/list.List[PIECE]
  mut current : PIECE
  mut piece_x : Int
  mut piece_y : Int
  mut piece_shape : Array[Array[Int]]
  mut score : Int
}

pub fn reset_game(self : Tetris) -> Unit {
  self.dead = false
  self.score = 0
  self.grid = for i = 0, grid = @immut/list.List::Nil
                  i < grid_row_count
                  i = i + 1, grid = Cons(Array::make(grid_col_count, 0), grid) {

  } else {
    grid
  }
  self.dead = self.generate_piece()
}

pub fn generate_piece(self : Tetris) -> Bool {
  self.current = self.get_next_piece(true)
  self.piece_shape = self.current.piece_shape()
  self.piece_x = grid_col_count / 2 - self.piece_shape[0].length() / 2
  self.piece_y = 0
  return check_collision(
    self.grid,
    self.piece_shape,
    (self.piece_x, self.piece_y),
  )
}

pub fn get_next_piece(self : Tetris, pop : Bool) -> PIECE {
  if self.piece_pool.length() == 0 {
    self.generate_piece_pool()
  }
  match self.piece_pool {
    Nil => abort("impossible")
    Cons(cur, n) => {
      if pop {
        self.piece_pool = n
      }
      cur
    }
  }
}

pub fn generate_piece_pool(self : Tetris) -> Unit {
  self.piece_pool = @immut/list.of(
    [PIECE::I, PIECE::J, PIECE::L, PIECE::O, PIECE::S, PIECE::T, PIECE::Z],
  )
}
// TODO:shuffle

pub fn on_piece_collision(self : Tetris) -> Unit {
  let len_r = self.piece_shape.length()
  let len_c = self.piece_shape[0].length()
  let y = self.piece_y - 1

  // Add the current shap to grid
  self.grid.eachi(
    fn {
      r, v => {
        if r < y || r >= y + len_r {
          return
        }
        for c = 0; c < len_c; c = c + 1 {
          if self.piece_shape[r - y][c] == 0 {
            continue c + 1
          }
          v[c + self.piece_x] = self.piece_shape[r - y][c]
        }
      }
    },
  )

  // Delete the complete row
  let (new_grid, row_completed) = self.grid.fold_right(
    init=(@immut/list.List::Nil, 0),
    fn {
      v, (new_grid, row_completed) =>
        if v.contains(0) {
          (Cons(v, new_grid), row_completed)
        } else {
          (new_grid, row_completed + 1)
        }
    },
  )
  // 1 line == 1 score
  self.score = self.score + row_completed

  // Insert blank row at the top
  self.grid = for i = 0, new_grid = new_grid
                  i < row_completed
                  i = i + 1, new_grid = Cons(
                      Array::make(grid_col_count, 0),
                      new_grid,
                    ) {

  } else {
    new_grid
  }
  self.dead = self.generate_piece()
}

pub fn drop_piece(self : Tetris, instant : Bool) -> Unit {
  if instant {
    let y = get_effective_height(
      self.grid,
      self.piece_shape,
      (self.piece_x, self.piece_y),
    )
    self.piece_y = y + 1
  } else {
    self.piece_y = self.piece_y + 1
  }
  if instant == false && check_collision(
    self.grid,
    self.piece_shape,
    (self.piece_x, self.piece_y),
  ) == false {
    return
  }
  self.on_piece_collision()
}

pub fn move_piece(self : Tetris, delta : Int) -> Unit {
  let mut new_x = self.piece_x + delta
  new_x = @math.maximum(
    0,
    @math.minimum(new_x, grid_col_count - self.piece_shape[0].length()),
  )
  if check_collision(self.grid, self.piece_shape, (new_x, self.piece_y)) {
    return
  }
  self.piece_x = new_x
}

pub fn rotate_piece(self : Tetris) -> Unit {
  let r = self.piece_shape.length()
  let c = self.piece_shape[0].length()
  let new_shap = Array::make(c, Array::make(r, 0))
  for i = 0; i < c; i = i + 1 {
    new_shap[i] = Array::make(r, 0)
  }
  for i_c = 0; i_c < c; i_c = i_c + 1 {
    for i_r = 0; i_r < r; i_r = i_r + 1 {
      new_shap[i_c][i_r] = self.piece_shape[r - i_r - 1][i_c]
    }
  }
  let mut new_x = self.piece_x
  if new_x + new_shap[0].length() > grid_col_count {
    new_x = grid_col_count - new_shap[0].length()
  }
  if check_collision(self.grid, new_shap, (new_x, self.piece_y)) {
    return
  }
  self.piece_x = new_x
  self.piece_shape = new_shap
}

pub fn step(tetris : Tetris, action : Int) -> Unit {
  if tetris.dead {
    return
  }
  match action {
    // move left
    1 => tetris.move_piece(-1)
    // move right
    2 => tetris.move_piece(1)
    // rotate
    3 => tetris.rotate_piece()
    // instant
    4 => tetris.drop_piece(true)
    _ => tetris.drop_piece(false)
  }
}

pub fn new() -> Tetris {
  let tetris = {
    dead: false,
    grid: Nil,
    piece_pool: Nil,
    current: I,
    piece_x: 0,
    piece_y: 0,
    piece_shape: PIECE::I.piece_shape(),
    score: 0,
  }
  tetris.reset_game()
  tetris
}

pub fn get_score(tetris : Tetris) -> Int {
  tetris.score
}
