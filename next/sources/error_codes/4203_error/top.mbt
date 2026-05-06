///|
priv enum Message {
  Text(String)
}

///|
fn build(make : (String) -> Message) -> Message {
  make("ready")
}

///|
fn read(message : Message) -> String {
  match message {
    Text(value) => value
  }
}

///|
test {
  inspect(read(Text("used")), content="used")
  let _ = build(Text)
}
