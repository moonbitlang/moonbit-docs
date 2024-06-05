fn set_stroke_color_ffi(self : Canvas_ctx, color : @extern.JsString) = "canvas" "set_stroke_color"

fn set_stroke_color(self : Canvas_ctx, color : String) -> Unit {
  self.set_stroke_color_ffi(@extern.JsString::from_string(color))
}

fn set_line_width(self : Canvas_ctx, width : Double) = "canvas" "set_line_width"

fn stroke_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "stroke_rect"

fn fill_rect(self : Canvas_ctx, x : Int, y : Int, width : Int, height : Int) = "canvas" "fill_rect"

fn set_fill_style_ffi(self : Canvas_ctx, color : @extern.JsString) = "canvas" "set_fill_style"

fn set_fill_style(self : Canvas_ctx, color : String) -> Unit {
  self.set_fill_style_ffi(@extern.JsString::from_string(color))
}
