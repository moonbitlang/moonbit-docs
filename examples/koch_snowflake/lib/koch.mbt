type Canvas_ctx

func begin_path(self : Canvas_ctx) = "canvas" "begin_path"

func clear_rect(self : Canvas_ctx, x : Float64, y : Float64, w : Float64,
        h : Float64) = "canvas" "clear_rect"

func move_to(self : Canvas_ctx, x : Float64, y : Float64) = "canvas" "move_to"

func line_to(self : Canvas_ctx, x : Float64, y : Float64) = "canvas" "line_to"

func stroke(self : Canvas_ctx) = "canvas" "stroke"

func sqrt(x : Float64) -> Float64 = "canvas" "sqrt"

func cos(x : Float64) -> Float64 = "canvas" "cos"

func get_pi() -> Float64 = "canvas" "get_pi"

func koch(ctx : Canvas_ctx, x1 : Float64, y1 : Float64, x2 : Float64,
        y2 : Float64, n : Float64, m : Float64) {
  ctx.clear_rect(0.0, 0.0, 400.0, 400.0)
  let x3 = (x2 - x1) / 3.0 + x1
  let y3 = (y2 - y1) / 3.0 + y1
  let x4 = (x2 - x1) / 3.0 * 2.0 + x1
  let y4 = (y2 - y1) / 3.0 * 2.0 + y1
  let x5 = x3 + (x2 - x1 - (y2 - y1) * sqrt(3.0)) / 6.0
  let y5 = y3 + ((x2 - x1) * sqrt(3.0) + (y2 - y1)) / 6.0
  let n = n + 1.0
  if n == m {
    ctx.move_to(x1, y1)
    ctx.line_to(x3, y3)
    ctx.line_to(x5, y5)
    ctx.line_to(x4, y4)
    ctx.line_to(x2, y2)
    ctx.stroke()
    return
  }
  koch(ctx, x1, y1, x3, y3, n, m)
  koch(ctx, x3, y3, x5, y5, n, m)
  koch(ctx, x5, y5, x4, y4, n, m)
  koch(ctx, x4, y4, x2, y2, n, m)
}

pub func draw(ctx : Canvas_ctx, deep : Float64) {
  ctx.begin_path()
  let y = 80.0 + cos(get_pi() / 6.0) * 200.0
  koch(ctx, 150.0, y, 250.0, 80.0, 0.0, deep)
  koch(ctx, 250.0, 80.0, 50.0, 80.0, 0.0, deep)
  koch(ctx, 50.0, 80.0, 150.0, y, 0.0, deep)
}

