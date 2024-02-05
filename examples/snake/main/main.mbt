pub fn new() -> @lib.GameState{
  return @lib.new()
}

pub fn step(game: @lib.GameState, a: Int){
  @lib.tran_step(game, a)
}

pub fn draw(canvas : @lib.Canvas_ctx, game : @lib.GameState){
  @lib.draw(canvas, game)
}

fn init {
  ()
}
