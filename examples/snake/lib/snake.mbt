let grid_row_count = 20

let grid_col_count = 20

enum Direction{
  Up
  Down
  Left
  Right
  Default
}

enum GridType{
  Body
  Food
  Default
}

// enum Action{
//   1
//   2
//   3
//   4
//   5
// }

pub fn grid_num(self: GridType) -> Int{
  match self{
    Body => 1
    Food => 2
    Default => 0
  }
}

pub fn dir_posi(self: Direction) -> Position{
  match self{
    Up => {x: 0, y: -1}
    Down => {x: 0, y: 1}
    Left => {x: -1, y: 0}
    Right => {x: 1, y: 0}
    Default => {x: 0, y: 0}
  }
}

fn Direction::op_equal(x: Direction, y: Direction) -> Bool{
  let x0: Position = dir_posi(x)
  let y0: Position = dir_posi(y)
  if (x0.x == y0.x && x0.y == y0.y){
    true
  }else{
    false
  }
}

struct Position{
	mut x: Int
	mut y: Int
}

struct GameState{
	mut grid:  Array[Int]
	mut body:  List[Position]
	mut dir:   Direction
}

pub fn initialize(self: GameState){
  self.grid = Array::make(grid_row_count*grid_col_count, 0)
  self.dir = Up

  self.body = Cons({x: grid_col_count/2, y: grid_col_count/2}, Nil)
  self.grid[grid_col_count/2 * grid_col_count + grid_col_count/2] = 1

  self.generate_Food()

}

fn setGridType(self: GameState, p: Position, t: GridType){
  self.grid[p.y * grid_col_count + p.x] = grid_num(t)

}

fn random() -> Double = "Math" "random"
fn floor(i: Double) -> Int = "Math" "floor"

fn generate_Food(self: GameState){
  while true {
    let i : Int = floor(random() * 20.0)
    let j : Int = floor(random() * 20.0)
    
    if(self.grid[j * grid_col_count + i] == grid_num(Default)){
      self.setGridType({x: i, y: j}, Food)
      return
    }
  }
}

fn go_step(self: GameState){
  // if (prev == Up && self.dir == Down) ||  (prev == Down && self.dir == Up) || (prev == Left && self.dir == Right) || (prev == Right && self.dir == Left){
  //   self.dir = prev
  // }
  let head : Position = get_head(self.body)
  let newHead : Position = {x: head.x , y: head.y }

  newHead.x = dir_posi(self.dir).x + newHead.x 
  newHead.y = dir_posi(self.dir).y + newHead.y

  newHead.x = (newHead.x + grid_col_count) % grid_col_count
  newHead.y = (newHead.y + grid_col_count) % grid_col_count

  if self.grid[newHead.y * grid_col_count + newHead.x] == 1{

    initialize(self)
    return
  }else if self.grid[newHead.y * grid_col_count + newHead.x] == 2{
    
    self.setGridType(newHead, Body)
    self.body = Cons(newHead, self.body)
    generate_Food(self)
  }else {

    self.setGridType(newHead, Body)
    self.body = Cons(newHead, self.body)
    self.setGridType(get_tail(self.body), Default)
    self.body = delete_tail(self.body)
  }

}

pub fn step(self : GameState, action : Direction) {

  match action {
    // move up
    Up =>{
      if length(self.body) == 1{
        self.dir = Up
      }else{
        if self.dir == Left || self.dir == Right || self.dir == Up{
          self.dir = Up
        }else{
          self.dir = self.dir
        }
      }
       
      }
      
    // move down
    Down =>{
      if length(self.body) == 1{
        self.dir = Down
      }else{
        if self.dir == Left || self.dir == Right || self.dir == Down{
          self.dir = Down
        }else{
          self.dir = self.dir
        }
      }
       
      }
      
    // move left
    Left =>{
      if length(self.body) == 1{
        self.dir = Left
      }else{
        if self.dir == Up || self.dir == Left || self.dir == Down{
          self.dir = Left
        }else{
          self.dir = self.dir
        }  
      }
 
      }
      
    // move right
    Right =>{
      if length(self.body) == 1{
        self.dir = Right
      }else{
        if self.dir == Up || self.dir == Right || self.dir == Down{
          self.dir = Right
        }else{
          self.dir = self.dir
        }
      }
      }
       
    _ =>{
      self.dir = self.dir
      }
       
  }

  self.go_step()
}

pub fn tran_step(self : GameState, a : Int){
  let mut action : Direction = Default
  match a {
    1 => action = Up
    2 => action = Down
    3 => action = Left
    4 => action = Right
    _ => action = Default
  }

  self.step(action)  
}

pub fn new() -> GameState{
  let game: GameState = {
    grid:  [],
	  body:  Nil,
	  dir:   Up
  }
  game.initialize()
  game
}