fn main {
  let a : @string.View = "asdf"
  loop a {
    [_, .. d] as a => {
      println(a)
      continue d
    }
    [] => ()
  }
}
