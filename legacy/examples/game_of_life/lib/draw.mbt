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

type Canvas_ctx

fn set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

fn move_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "move_to"

fn line_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "line_to"

fn begin_path(self : Canvas_ctx) = "canvas" "begin_path"

fn stroke(self : Canvas_ctx) = "canvas" "stroke"

fn fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

fn set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"

let cell_size = 5

pub fn draw_grid(canvas : Canvas_ctx) -> Unit {
  canvas.begin_path()
  canvas.set_stroke_color(0xcccccc)
  let mut i = 0
  while i <= 64 {
    canvas.move_to(i * (cell_size + 1) + 1, 0)
    canvas.line_to(i * (cell_size + 1) + 1, (cell_size + 1) * 64 + 1)
    i = i + 1
  }
  let mut j = 0
  while j <= 64 {
    canvas.move_to(0, j * (cell_size + 1) + 1)
    canvas.line_to((cell_size + 1) * 64 + 1, j * (cell_size + 1) + 1)
    j = j + 1
  }
  canvas.stroke()
}

pub fn draw_cell(
  canvas : Canvas_ctx,
  universe : Universe,
  dead : Int,
  alive : Int
) -> Unit {
  canvas.begin_path()
  let mut row = 0
  while row < 64 {
    let mut col = 0
    while col < 64 {
      let idx = universe.get_index(row, col)
      let color = if universe.get_cell(idx) == 0 { dead } else { alive }
      canvas.set_fill_style(color)
      canvas.fill_rect(col * 6 + 1, row * 6 + 1, 5, 5)
      col = col + 1
    }
    row = row + 1
  }
  canvas.stroke()
}
