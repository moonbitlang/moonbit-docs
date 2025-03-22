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

pub(all) extern type Canvas_ctx

fn body_color(grid : GridType) -> String {
  match grid {
    Body => "#ffb900"
    Food => "#2753f1"
    None => "#dcdcdc"
  }
}

let border_color = "#00263f"

pub fn draw(canvas : Canvas_ctx, snake : GameState) -> Unit {
  // draw background
  for c = 0; c < grid_col_count; c = c + 1 {
    canvas.set_fill_style(body_color(None))
    canvas.fill_rect(c, 0, 1, grid_row_count)
  }
  draw_piece(canvas, snake.grid, (0, 0))
}

fn draw_piece(
  canvas : Canvas_ctx,
  matrix : FixedArray[GridType],
  offset : (Int, Int)
) -> Unit {
  matrix.eachi(
    fn {
      _, None => ()
      c, grid => {
        let c0 = c % grid_col_count
        let r = c / grid_col_count
        canvas.set_fill_style(body_color(grid))
        canvas.fill_rect(offset.0 + c0, r, 1, 1)
        canvas.set_stroke_color(border_color)
        canvas.set_line_width(0.1)
        canvas.stroke_rect(c0, r, 1, 1)
      }
    },
  )
}
