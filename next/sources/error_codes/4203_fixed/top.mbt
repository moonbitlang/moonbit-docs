///|
priv enum Message {
  Text(String)
}

///|
fn build(make : (String) -> Message) -> Message {
  make("ready")
}

///|
test {
  let message = build(value => Text(value))
  match message {
    Text(value) => inspect(value, content="ready")
  }
}
