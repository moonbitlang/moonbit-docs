```moonbit
pub fn greeting() -> String {
  "Hello!"
}

fn init {
  fn local_greeting() -> String {
    "Hello, world!"
  }
  let _ = local_greeting
}
```