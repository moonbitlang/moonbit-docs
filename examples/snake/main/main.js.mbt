extern "js" fn request_animation_frame(callback : (Double) -> Unit) -> Int =
  #|window.requestAnimationFrame

extern "js" fn set_on_keydown(callback : (KeyboardEvent) -> Unit) =
  #|(callback) => { document.onkeydown = callback }

extern "js" fn get_context() -> @lib.Canvas_ctx =
  #|() => {
  #|  const context = globalThis["canvas"].getContext("2d");
  #|  context.scale(24, 24);
  #|  return context;
  #|}

type KeyboardEvent

extern "js" fn key_ffi(self : KeyboardEvent) -> @extern.JsString =
  #|(event) => event.key

fn key(self : KeyboardEvent) -> String {
  self.key_ffi().to_string()
}
