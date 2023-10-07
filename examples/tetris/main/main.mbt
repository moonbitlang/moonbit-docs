pub func draw(canvas : @lib.Canvas_ctx, tetris : @lib.Tetris) {
  @lib.draw(canvas, tetris)
}

pub func step(tetris : @lib.Tetris, action : Int) {
  @lib.step(tetris, action)
}

pub func new() -> @lib.Tetris {
  return @lib.new()
}

pub func get_score(tetris : @lib.Tetris) -> Int {
  return @lib.get_score(tetris)
}

func init {
  ()
}

