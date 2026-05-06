///|
enum Message {
  Add(String)
}

///|
fn[T] perform(message : (T) -> Message, produce : () -> T) -> Message {
  message(produce())
}

///|
fn main {
  match perform(x => Add(x), fn() { "Hello, world!" }) {
    Add(message) => println(message)
  }
}
