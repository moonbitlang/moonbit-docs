pub func calc_color(col : Int, row : Int, ox : Float64, oy : Float64,
        width : Float64) -> Int {
  @lib.calc_color(col, row, ox, oy, width)
}

pub func draw_color(image_data : @lib.ImageData, col : Int, row : Int, rgb : Int) {
  @lib.draw_color(image_data, col, row, rgb)
}

func init {
  ()
}

