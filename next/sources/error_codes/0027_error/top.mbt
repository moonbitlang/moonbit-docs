enum Message {
  Add(String)
}

fn perform[T](message : (T) -> Message, produce : () -> T) -> Message {
  //
  // Warning: The syntax fn f[..] for declaring polymorphic function is 
  // deprecated. Use fn[..] f instead.
  message(produce())
}

fn main {
  match perform(value => Add(value), fn() { "Hello, world!" }) {
    Add(message) => println(message)
  }
}
