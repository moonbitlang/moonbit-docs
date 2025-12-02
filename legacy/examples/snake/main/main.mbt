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
let state : @lib.GameState = @lib.new()

///|
let context : @lib.Canvas_ctx = get_context()

///|
let last_frame : Ref[Double] = { val: 0.0 }

///|
let game_interval = 500.0

///|
fn update(time : Double) -> Unit {
  if time - last_frame.val > game_interval {
    @lib.step(state, @lib.Direction::Default)
    @lib.draw(context, state)
    last_frame.val = time
  } else {
    @lib.draw(context, state)
  }
  request_animation_frame(update) |> ignore
}

///|
fn main {
  set_on_keydown(fn(event) {
    if last_frame.val < 0.0 { // not started yet
      return
    }
    match event.key() {
      "ArrowLeft" => {
        @lib.step(state, @lib.Direction::Left)
        @lib.draw(context, state)
      }
      "ArrowRight" => {
        @lib.step(state, @lib.Direction::Right)
        @lib.draw(context, state)
      }
      "ArrowDown" => {
        @lib.step(state, @lib.Direction::Down)
        @lib.draw(context, state)
      }
      "ArrowUp" => {
        @lib.step(state, @lib.Direction::Up)
        @lib.draw(context, state)
      }
      _ => ()
    }
  })
  request_animation_frame(update) |> ignore
}
