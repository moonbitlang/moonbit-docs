type Canvas_ctx

func set_stroke_color(self : Canvas_ctx, color : Int) = "canvas" "set_stroke_color"

func set_line_width(self : Canvas_ctx, width : Float64) = "canvas" "set_line_width"

func stroke_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "stroke_rect"

func fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

func set_fill_style(self : Canvas_ctx, color : Int) = "canvas" "set_fill_style"

func draw_game_over(self: Canvas_ctx) = "canvas" "draw_game_over"



pub func draw(canvas : Canvas_ctx, tetris : Tetris) {
    var c = 0

    //draw backgroud
    while c < grid_col_count {
      let color = if (c%2) == 0 {0} else {1} 
      canvas.set_fill_style(color)
      canvas.fill_rect(c, 0, 1, grid_row_count)
      c = c + 1
    }
    
    draw_piece(canvas, tetris.grid, (0, 0))
    draw_piece(canvas, tetris.pice_shap.stream(), (tetris.pice_x, tetris.pice_y))

    if tetris.dead {
      canvas.draw_game_over()
    }
}

pub func draw_piece(canvas:Canvas_ctx, matrix:List[Array[Int]], offset:(Int, Int)) {
    
    fn go(l:List[Array[Int]], r:Int, canvas:Canvas_ctx) {
      match l {
        Cons(v, n) => {
          var c = 0
          while c < v.length() {
            if v[c] == 0 {
              c = c+1
              continue
            }
            canvas.set_fill_style(v[c]+1)
            canvas.fill_rect(offset.0 + c, offset.1 + r, 1, 1)
            canvas.set_stroke_color(0)
            canvas.set_line_width(0.1)
            canvas.stroke_rect(offset.0 + c, offset.1 + r, 1, 1)
            c = c + 1
          }
          go(n, r+1, canvas)
        }
        Nil => ()
      }
    }
    go(matrix, 0, canvas)
}
