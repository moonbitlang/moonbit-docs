pub fn draw(canvas : @lib.Canvas_ctx, tetris : @lib.Tetris) {
  @lib.draw(canvas, tetris)
}

pub fn step(tetris : @lib.Tetris, action : Int) {
  @lib.step(tetris, action)
}

pub fn new() -> @lib.Tetris {
  return @lib.new()
}

pub fn get_score(tetris : @lib.Tetris) -> Int {
  return @lib.get_score(tetris)
}

fn init {
  ()
}

