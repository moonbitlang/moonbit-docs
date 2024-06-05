let state : @lib.GameState = @lib.new()

let context : @lib.Canvas_ctx = get_context()

let last_frame : Ref[Double] = { val: 0.0 }

let game_interval = 500.0

fn update(time : Double) -> Unit {
  if time - last_frame.val > game_interval {
    @lib.step(state, @lib.Direction::Default)
    @lib.draw(context, state)
    last_frame.val = time
  } else {
    @lib.draw(context, state)
  }
  request_animation_frame(update) |> ignore
}

fn main {
  set_on_keydown(
    fn(event) {
      if last_frame.val < 0.0 { // not started yet
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
  request_animation_frame(update) |> ignore
}
