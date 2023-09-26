type Canvas_ctx

func set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

func move_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "move_to"

func line_to(self : Canvas_ctx, x : Int, y : Int) = "canvas" "line_to"

func begin_path(self : Canvas_ctx) = "canvas" "begin_path"

func stroke(self : Canvas_ctx) = "canvas" "stroke"

func fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

func set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"

let cell_size = 5

pub func draw_grid(canvas : Canvas_ctx) {
  canvas.begin_path()
  canvas.set_stroke_color(0xcccccc)
  var i = 0
  while i <= 64 {
    canvas.move_to(i * (cell_size + 1) + 1, 0)
    canvas.line_to(i * (cell_size + 1) + 1, (cell_size + 1) * 64 + 1)
    i = i + 1
  }
  var j = 0
  while j <= 64 {
    canvas.move_to(0, j * (cell_size + 1) + 1)
    canvas.line_to((cell_size + 1) * 64 + 1, j * (cell_size + 1) + 1)
    j = j + 1
  }
  canvas.stroke()
}

pub func draw_cell(canvas : Canvas_ctx, universe : Universe, dead : Int,
        alive : Int) {
  canvas.begin_path()
  var row = 0
  while row < 64 {
    var col = 0
    while col < 64 {
      let idx = universe.get_index(row, col)
      let color = if universe.get_cell(idx) == 0 {
        dead
      } else {
        alive
      }
      canvas.set_fill_style(color)
      canvas.fill_rect(col * 6 + 1, row * 6 + 1, 5, 5)
      col = col + 1
    }
    row = row + 1
  }
  canvas.stroke()
}

