```moonbit
type Code Int

fn Code::new(value : Int) -> Code {
  return value
}

fn init {
  let _ = Code::new(1)
}
```