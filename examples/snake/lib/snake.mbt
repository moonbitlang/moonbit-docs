let grid_row_count = 20

let grid_col_count = 20

pub enum Direction {
  Up
  Down
  Left
  Right
  Default
}

enum GridType {
  Body
  Food
  Default
} derive(Eq)

fn dir_posi(self : Direction) -> Position {
  match self {
    Up => { x: 0, y: -1 }
    Down => { x: 0, y: 1 }
    Left => { x: -1, y: 0 }
    Right => { x: 1, y: 0 }
    Default => { x: 0, y: 0 }
  }
}

fn Direction::op_equal(x : Direction, y : Direction) -> Bool {
  let x0 : Position = dir_posi(x)
  let y0 : Position = dir_posi(y)
  if x0.x == y0.x && x0.y == y0.y {
    true
  } else {
    false
  }
}

struct Position {
  mut x : Int
  mut y : Int
}

struct GameState {
  mut grid : Array[GridType]
  mut body : List[Position]
  mut dir : Direction
}

fn initialize(self : GameState) -> Unit {
  self.grid = Array::make(grid_row_count * grid_col_count, Default)
  self.dir = Up
  self.body = Cons({ x: grid_col_count / 2, y: grid_col_count / 2 }, Nil)
  self.grid[grid_col_count / 2 * grid_col_count + grid_col_count / 2] = Body
  self.generate_Food()
}

fn setGridType(self : GameState, p : Position, t : GridType) -> Unit {
  self.grid[p.y * grid_col_count + p.x] = t
}

pub let random : Ref[Int64] = { val: 314159265L }

fn generate_Food(self : GameState) -> Unit {
  while true {
    let (i, seed) = random_lcg(random.val)
    let (j, seed) = random_lcg(seed)
    random.val = seed
    let i = i.mod_u(20)
    let j = j.mod_u(20)
    if self.grid[j * grid_col_count + i] == Default {
      self.setGridType({ x: i, y: j }, Food)
      return
    }
  }
}

fn go_step(self : GameState) -> Unit {
  // if (prev == Up && self.dir == Down) ||  (prev == Down && self.dir == Up) || (prev == Left && self.dir == Right) || (prev == Right && self.dir == Left){
  //   self.dir = prev
  // }
  let head : Position = get_head(self.body)
  let newHead : Position = { x: head.x, y: head.y }
  newHead.x = dir_posi(self.dir).x + newHead.x
  newHead.y = dir_posi(self.dir).y + newHead.y
  newHead.x = (newHead.x + grid_col_count) % grid_col_count
  newHead.y = (newHead.y + grid_col_count) % grid_col_count
  if self.grid[newHead.y * grid_col_count + newHead.x] == Body {
    initialize(self)
    return
  } else if self.grid[newHead.y * grid_col_count + newHead.x] == Food {
    self.setGridType(newHead, Body)
    self.body = Cons(newHead, self.body)
    generate_Food(self)
  } else {
    self.setGridType(newHead, Body)
    self.body = Cons(newHead, self.body)
    self.setGridType(get_tail(self.body), Default)
    self.body = delete_tail(self.body)
  }
}

pub fn step(self : GameState, action : Direction) -> Unit {
  match (action, self.dir) {
    (Up, Down) | (Left, Right) | (Right, Left) | (Down, Up) =>
      if self.body.length() == 1 {
        self.dir = action
        self.go_step()
      }
    _ => {
      if action != Default {
        self.dir = action
      }
      self.go_step()
    }
  }
}

pub fn new() -> GameState {
  let game : GameState = { grid: [], body: Nil, dir: Up }
  game.initialize()
  game
}
