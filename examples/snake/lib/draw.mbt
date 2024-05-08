fn body_color(grid : GridType) -> String {
  match grid {
    Body => "#ffb900"
    Food => "#2753f1"
    Default => "#dcdcdc"
  }
}

let border_color = "#00263f"

pub fn draw(canvas : @canvas.Canvas2D, snake : GameState) -> Unit {
  // draw backgroud
  for c = 0; c < grid_col_count; c = c + 1 {
    canvas.set_fill_style(Color(body_color(Default)))
    canvas.fill_rect(c.to_double(), 0.0, 1.0, grid_row_count.to_double())
  }
  draw_piece(canvas, snake.grid, (0, 0))
}

fn draw_piece(
  canvas : @canvas.Canvas2D,
  matrix : Array[GridType],
  offset : (Int, Int)
) -> Unit {
  let mut r = 0
  let mut c0 = 0
  for c = 0; c < matrix.length(); c = c + 1 {
    if matrix[c] == Default {
      continue c + 1
    }
    c0 = c % grid_col_count
    r = c / grid_col_count
    canvas.set_fill_style(Color(body_color(matrix[c])))
    canvas.fill_rect(offset.0 + c0 |> Int::to_double, r.to_double(), 1.0, 1.0)
    canvas.set_stroke_style(Color(border_color))
    canvas.set_line_width(0.1)
    canvas.stroke_rect(c0.to_double(), r.to_double(), 1.0, 1.0)
  }
}
