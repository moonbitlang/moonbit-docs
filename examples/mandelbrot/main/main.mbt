pub fn calc_color(col : Int, row : Int, ox : Double, oy : Double,
        width : Double) -> Int {
  @lib.calc_color(col, row, ox, oy, width)
}

pub fn draw_color(image_data : @lib.ImageData, col : Int, row : Int, rgb : Int) {
  @lib.draw_color(image_data, col, row, rgb)
}

fn init {
  ()
}

