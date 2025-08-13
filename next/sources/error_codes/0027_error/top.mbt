enum Message {
  Add(String)
} derive(Show)

fn perform[T](message : (T) -> Message, produce : () -> T) -> Message {
  message(produce())
}

fn main {
  println(perform(Add, fn() { "Hello, world!" }))
  //              ^^^
  // Warning: Using constructor as function directly is
  // deprecated. Use the partial application syntax instead
}
