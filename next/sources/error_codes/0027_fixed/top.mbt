///|
enum Message {
  Add(String)
} derive(Show)

///|
fn[T] perform(message : (T) -> Message, produce : () -> T) -> Message {
  message(produce())
}

///|
fn main {
  println(perform(Add(_), fn() { "Hello, world!" }))
}
