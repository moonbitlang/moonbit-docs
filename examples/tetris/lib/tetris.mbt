struct Tetris {
  mut dead : Bool
  mut grid : List[Array[Int]]
  mut piece_pool : List[PIECE]
  mut current : PIECE
  mut piece_x : Int
  mut piece_y : Int
  mut piece_shape : Array[Array[Int]]
  mut score : Int
  mut row_completed : Int
}

pub fn reset_game(self : Tetris) -> Unit {
  self.dead = false
  self.score = 0
  self.row_completed = 0
  fn go(i : Int) -> List[Array[Int]] {
    if i == grid_row_count - 1 {
      Cons(Array::make(grid_col_count, 0), Nil)
    } else {
      Cons(Array::make(grid_col_count, 0), go(i + 1))
    }
  }

  self.grid = go(0)
  self.dead = self.generate_piece()
}

pub fn generate_piece(self : Tetris) -> Bool {
  self.current = self.get_next_piece(true)
  self.piece_shape = self.current.piece_shape()
  self.piece_x = grid_col_count / 2 - self.piece_shape[0].length() / 2
  self.piece_y = 0
  return check_collision(self.grid, self.piece_shape, (self.piece_x, self.piece_y))
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
  self.piece_pool = List::[
    PIECE::I,
    PIECE::J,
    PIECE::L,
    PIECE::O,
    PIECE::S,
    PIECE::T,
    PIECE::Z,
  ]
}
// TODO:shuffle

pub fn on_piece_collision(self : Tetris) -> Unit {
  let len_r = self.piece_shape.length()
  let len_c = self.piece_shape[0].length()
  let y = self.piece_y - 1

  // Add the current shap to grid
  fn go1(l : List[Array[Int]], r : Int) {
    match l {
      Cons(v, n) => {
        if r < y {
          return go1(n, r + 1)
        }
        if r >= y + len_r {
          return
        }
        let mut c = 0
        while c < len_c {
          if self.piece_shape[r - y][c] == 0 {
            c = c + 1
            continue
          }
          v[c + self.piece_x] = self.piece_shape[r - y][c]
          c = c + 1
        }
        return go1(n, r + 1)
      }
      Nil => ()
    }
  }

  go1(self.grid, 0)

  // Delete the complete row
  self.row_completed = 0
  fn go2(l : List[Array[Int]]) -> List[Array[Int]] {
    match l {
      Nil => Nil
      Cons(v, n) =>
        if v.contains(0) {
          return Cons(v, go2(n))
        } else {
          self.row_completed = self.row_completed + 1
          return go2(n)
        }
    }
  }

  let mut new_grid : List[Array[Int]] = Nil
  new_grid = go2(self.grid)
  // 1 line == 1 score
  self.score = self.score + self.row_completed

  // Insert blank row at the top
  let mut i = 0
  while i < self.row_completed {
    new_grid = Cons(Array::make(grid_col_count, 0), new_grid)
    i = i + 1
  }
  self.row_completed = 0
  self.grid = new_grid
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
  new_x = @math.maximum(0, @math.minimum(new_x, grid_col_count - self.piece_shape[0].length()))
  if check_collision(self.grid, self.piece_shape, (new_x, self.piece_y)) {
    return
  }
  self.piece_x = new_x
}

pub fn rotate_piece(self : Tetris) -> Unit {
  let r = self.piece_shape.length()
  let c = self.piece_shape[0].length()
  let new_shap = Array::make(c, Array::make(r, 0))
  let mut i = 0
  while i < c {
    new_shap[i] = Array::make(r, 0)
    i = i + 1
  }
  let mut i_c = 0
  while i_c < c {
    let mut i_r = 0
    while i_r < r {
      new_shap[i_c][i_r] = self.piece_shape[r - i_r - 1][i_c]
      i_r = i_r + 1
    }
    i_c = i_c + 1
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
    _ => ()
  }
  tetris.drop_piece(false)
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
    row_completed: 0,
  }
  tetris.reset_game()
  tetris
}

pub fn get_score(tetris : Tetris) -> Int {
  tetris.score
}
