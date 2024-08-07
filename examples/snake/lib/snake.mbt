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

let grid_row_count = 20

let grid_col_count = 20

pub enum Direction {
  Up
  Down
  Left
  Right
  Default
} derive(Eq)

enum GridType {
  Body
  Food
  None
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

struct Position {
  x : Int
  y : Int
}

struct GameState {
  grid : FixedArray[GridType]
  body : @deque.T[Position]
  mut dir : Direction
}

fn initialize(self : GameState) -> Unit {
  self.grid.fill(None)
  self.dir = Up
  self.body.clear()
  self.body.push_back({ x: grid_col_count / 2, y: grid_col_count / 2 })
  self.grid[grid_col_count / 2 * grid_col_count + grid_col_count / 2] = Body
  self.generate_Food()
}

fn setGridType(self : GameState, p : Position, t : GridType) -> Unit {
  self.grid[p.y * grid_col_count + p.x] = t
}

fn random() -> Double = "Math" "random"

fn floor(i : Double) -> Int = "Math" "floor"

fn generate_Food(self : GameState) -> Unit {
  while true {
    let i : Int = floor(random() * 20.0)
    let j : Int = floor(random() * 20.0)
    if self.grid[j * grid_col_count + i] == None {
      self.setGridType({ x: i, y: j }, Food)
      return
    }
  }
}

fn go_step(self : GameState) -> Unit {
  // if (prev == Up && self.dir == Down) ||  (prev == Down && self.dir == Up) || (prev == Left && self.dir == Right) || (prev == Right && self.dir == Left){
  //   self.dir = prev
  // }
  let head : Position = self.body.front().unwrap()
  let newHead = {
    x: (head.x + dir_posi(self.dir).x + grid_col_count) % grid_col_count,
    y: (head.y + dir_posi(self.dir).y + grid_row_count) % grid_row_count,
  }
  if self.grid[newHead.y * grid_col_count + newHead.x] == Body {
    initialize(self)
    return
  } else if self.grid[newHead.y * grid_col_count + newHead.x] == Food {
    self.setGridType(newHead, Body)
    self.body.push_front(newHead)
    generate_Food(self)
  } else {
    self.setGridType(newHead, Body)
    self.body.push_front(newHead)
    self.setGridType(self.body.back().unwrap(), None)
    self.body.pop_back_exn()
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
  let game : GameState = {
    grid: FixedArray::make(grid_row_count * grid_col_count, None),
    body: @deque.new(),
    dir: Up,
  }
  game.initialize()
  game
}
