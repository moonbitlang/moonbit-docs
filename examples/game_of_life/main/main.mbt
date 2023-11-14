pub fn draw_grid(canvas : @lib.Canvas_ctx) {
  @lib.draw_grid(canvas)
}

pub fn draw_cell(canvas : @lib.Canvas_ctx, universe : @lib.Universe,
        dead : Int, alive : Int) {
  @lib.draw_cell(canvas, universe, dead, alive)
}

pub fn tick(universe : @lib.Universe) {
  @lib.tick(universe)
}

pub fn new() -> @lib.Universe {
  @lib.new()
}

fn init {
  ()
}

