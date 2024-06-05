fn request_animation_frame(callback : (Double) -> Unit) -> Int = "window" "requestAnimationFrame"

fn set_on_keydown(callback : (KeyboardEvent) -> Unit) = "document" "set_onkeydown"

fn get_context() -> @lib.Canvas_ctx = "canvas" "get_context"

type KeyboardEvent

fn key_ffi(self : KeyboardEvent) -> @extern.JsString = "keyboard_event" "key"

fn key(self : KeyboardEvent) -> String {
  self.key_ffi().to_string()
}