struct Tetris {
  mut dead : Bool
  mut grid : List[Array[Int]]
  mut pice_pool : List[PIECE]
  mut current : PIECE
  mut pice_x : Int
  mut pice_y : Int
  mut pice_shap : Array[Array[Int]]
  mut score : Int
  mut row_completed : Int
}

pub func reset_game(self : Tetris) {
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

pub func generate_piece(self : Tetris) -> Bool {
  self.current = self.get_next_piece(true)
  self.pice_shap = self.current.pice_shap()
  self.pice_x = grid_col_count / 2 - self.pice_shap[0].length() / 2
  self.pice_y = 0
  return check_collision(self.grid, self.pice_shap, (self.pice_x, self.pice_y))
}

pub func get_next_piece(self : Tetris, pop : Bool) -> PIECE {
  if self.pice_pool.length() == 0 {
    self.generate_piece_pool()
  }
  let Cons(cur, n) = self.pice_pool
  if pop {
    self.pice_pool = n
  }
  cur
}

pub func generate_piece_pool(self : Tetris) {
  self.pice_pool = [
    PIECE::I,
    PIECE::J,
    PIECE::L,
    PIECE::O,
    PIECE::S,
    PIECE::T,
    PIECE::Z,
  ].stream()
  // TODO:shuffle
}

pub func on_piece_collision(self : Tetris) {
  let len_r = self.pice_shap.length()
  let len_c = self.pice_shap[0].length()
  let y = self.pice_y - 1

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
        var c = 0
        while c < len_c {
          if self.pice_shap[r - y][c] == 0 {
            c = c + 1
            continue
          }
          v[c + self.pice_x] = self.pice_shap[r - y][c]
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
        if contain(v, 0) {
          return Cons(v, go2(n))
        } else {
          self.row_completed = self.row_completed + 1
          return go2(n)
        }
    }
  }

  var new_grid : List[Array[Int]] = Nil
  new_grid = go2(self.grid)
  // 1 line == 1 score
  self.score = self.score + self.row_completed

  // Insert blank row at the top
  var i = 0
  while i < self.row_completed {
    new_grid = Cons(Array::make(grid_col_count, 0), new_grid)
    i = i + 1
  }
  self.row_completed = 0
  self.grid = new_grid
  self.dead = self.generate_piece()
}

pub func drop_piece(self : Tetris, instant : Bool) {
  if instant {
    let y = get_effective_height(
      self.grid,
      self.pice_shap,
      (self.pice_x, self.pice_y),
    )
    self.pice_y = y + 1
  } else {
    self.pice_y = self.pice_y + 1
  }
  if instant == false && check_collision(
    self.grid,
    self.pice_shap,
    (self.pice_x, self.pice_y),
  ) == false {
    return
  }
  self.on_piece_collision()
}

pub func move_piece(self : Tetris, delta : Int) {
  var new_x = self.pice_x + delta
  new_x = max(0, min(new_x, grid_col_count - self.pice_shap[0].length()))
  if check_collision(self.grid, self.pice_shap, (new_x, self.pice_y)) {
    return
  }
  self.pice_x = new_x
}

pub func rotate_piece(self : Tetris) {
  let r = self.pice_shap.length()
  let c = self.pice_shap[0].length()
  let new_shap = Array::make(c, Array::make(r, 0))
  var i = 0
  while i < c {
    new_shap[i] = Array::make(r, 0)
    i = i + 1
  }
  var i_c = 0
  while i_c < c {
    var i_r = 0
    while i_r < r {
      new_shap[i_c][i_r] = self.pice_shap[r - i_r - 1][i_c]
      i_r = i_r + 1
    }
    i_c = i_c + 1
  }
  var new_x = self.pice_x
  if new_x + new_shap[0].length() > grid_col_count {
    new_x = grid_col_count - new_shap[0].length()
  }
  if check_collision(self.grid, new_shap, (new_x, self.pice_y)) {
    return
  }
  self.pice_x = new_x
  self.pice_shap = new_shap
}

pub func step(tetris : Tetris, action : Int) {
  if tetris.dead {
    return
  }
  match action {
    // move left
    1 =>
      tetris.move_piece(-1)
      // move right
    2 =>
      tetris.move_piece(1)
      // rotate
    3 =>
      tetris.rotate_piece()
      // instant
    4 => tetris.drop_piece(true)
    _ => ()
  }
  tetris.drop_piece(false)
}

pub func new() -> Tetris {
  let tetris = {
    dead: false,
    grid: Nil,
    pice_pool: Nil,
    current: I,
    pice_x: 0,
    pice_y: 0,
    pice_shap: PIECE::I.pice_shap(),
    score: 0,
    row_completed: 0,
  }
  tetris.reset_game()
  tetris
}

pub func get_score(tetris : Tetris) -> Int {
  tetris.score
}

