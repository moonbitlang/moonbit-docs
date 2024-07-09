pub type Canvas_ctx

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
