fn main {
  let a : @string.View = "asdf"
  let b = a
  loop a {
    [_, .. d] => {
      println(b)
      continue d
    }
    [] => ()
  }
}
