type! E

fn f() -> Unit!E {
  raise E
}

fn g() -> Unit! {
  try {
    f!()
  } catch {
    E => raise E
  }
}

fn main {
  try {
    g!()
  } catch {
    _ => println("Error")
  }
}
