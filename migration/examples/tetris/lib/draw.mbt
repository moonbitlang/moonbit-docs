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

type Canvas_ctx

fn set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

fn set_line_width(self : Canvas_ctx, width : Double) = "canvas" "set_line_width"

fn stroke_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "stroke_rect"

fn fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

fn set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"

fn draw_game_over(self : Canvas_ctx) = "canvas" "draw_game_over"

pub fn draw(canvas : Canvas_ctx, tetris : Tetris) -> Unit {
  // draw background
  for c = 0; c < grid_col_count; c = c + 1 {
    let color = if c % 2 == 0 { 0 } else { 1 }
    canvas.set_fill_style(color)
    canvas.fill_rect(c, 0, 1, grid_row_count)
  }
  draw_piece(canvas, tetris.grid, (0, 0))
  draw_piece(
    canvas,
    @immut/list.List::from_array(tetris.piece_shape),
    (tetris.piece_x, tetris.piece_y),
  )
  if tetris.dead {
    canvas.draw_game_over()
  }
}

pub fn draw_piece(
  canvas : Canvas_ctx,
  matrix : @immut/list.List[Array[Int]],
  offset : (Int, Int)
) -> Unit {
  canvas.set_stroke_color(0)
  canvas.set_line_width(0.1)
  matrix.eachi(
    fn {
      r, v =>
        for c = 0; c < v.length(); c = c + 1 {
          if v[c] == 0 {
            continue c + 1
          }
          canvas.set_fill_style(v[c] + 1)
          canvas.fill_rect(offset.0 + c, offset.1 + r, 1, 1)
          canvas.stroke_rect(offset.0 + c, offset.1 + r, 1, 1)
        }
    },
  )
}
