pub fn new() -> @lib.GameState{
  return @lib.new()
}

pub fn step(game: @lib.GameState, action: Int){
  @lib.step(game, action)
}

pub fn draw(canvas : @lib.Canvas_ctx, game : @lib.GameState){
  @lib.draw(canvas, game)
}

fn init {
  ()
}
