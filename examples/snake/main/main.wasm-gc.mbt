fn get_context() -> @canvas.Canvas2D = "game" "get_context"

let state : @lib.GameState = @lib.new()

let context : @canvas.Canvas2D = get_context()

let last_frame : Ref[Int64] = { val: 0L }

let game_interval = 500L

fn update(time : Int64) -> Unit {
  if time - last_frame.val > game_interval {
    @lib.step(state, @lib.Direction::Default)
    @lib.draw(context, state)
    last_frame.val = time
  } else {
    @lib.draw(context, state)
  }
  @canvas.request_animation_frame(update) |> ignore
}

fn main {
  @canvas.set_on_key_down(
    fn(event) {
      if last_frame.val <= 0L { // not started yet
        return
      }
      match event.key() {
        "ArrowLeft" => {
          @lib.step(state, @lib.Direction::Left)
          @lib.draw(context, state)
        }
        "ArrowRight" => {
          @lib.step(state, @lib.Direction::Right)
          @lib.draw(context, state)
        }
        "ArrowDown" => {
          @lib.step(state, @lib.Direction::Down)
          @lib.draw(context, state)
        }
        "ArrowUp" => {
          @lib.step(state, @lib.Direction::Up)
          @lib.draw(context, state)
        }
        _ => ()
      }
    },
  )
  @canvas.request_animation_frame(update) |> ignore
}
