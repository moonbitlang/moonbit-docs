pub func draw_grid(canvas : @lib.Canvas_ctx) {
  @lib.draw_grid(canvas)
}

pub func draw_cell(canvas : @lib.Canvas_ctx, universe : @lib.Universe,
        dead : Int, alive : Int) {
  @lib.draw_cell(canvas, universe, dead, alive)
}

pub func tick(universe : @lib.Universe) {
  @lib.tick(universe)
}

pub func new() -> @lib.Universe {
  @lib.new()
}

func init {
  ()
}

