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
  let _ = build(Text)
}
