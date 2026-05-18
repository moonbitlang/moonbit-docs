///|
suberror E

///|
fn f() -> Unit raise E {
  raise E
}

///|
fn g() -> Unit raise {
  f() catch {
    E => raise E
  }
}

///|
fn main {
  g() catch {
    _ => println("Error")
  }
}
