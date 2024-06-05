extern "js" fn set_stroke_color_ffi(
  self : Canvas_ctx,
  color : @extern.JsString
) =
  #|(ctx, color) => ctx.strokeStyle = color

fn set_stroke_color(self : Canvas_ctx, color : String) -> Unit {
  self.set_stroke_color_ffi(@extern.JsString::from_string(color))
}

extern "js" fn set_line_width(self : Canvas_ctx, width : Double) =
  #|(ctx, width) => ctx.lineWidth = width

extern "js" fn stroke_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) =
  #|(ctx, x, y, width, height) => ctx.strokeRect(x, y, width, height)

extern "js" fn fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) =
  #|(ctx, x, y, width, height) => ctx.fillRect(x, y, width, height)

extern "js" fn set_fill_style_ffi(self : Canvas_ctx, color : @extern.JsString) =
  #|(ctx, color) => ctx.fillStyle = color

fn set_fill_style(self : Canvas_ctx, color : String) -> Unit {
  self.set_fill_style_ffi(@extern.JsString::from_string(color))
}
