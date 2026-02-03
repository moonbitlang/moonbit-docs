///|
test (ctx : @test.Test) {
  let println = ctx.writeln(_)
  // start example
  let a : StringView = "asdf"
  loop a {
    [_, .. d] => {
      println(a)
      //      ^
      // Warning: The usage of 'a' is ambiguous. If it refers to the loop
      // variable, please use `as a` to bind it in the pattern. If it refers to
      // the original value of 'a' before entering the loop, please bind it to a
      // new binder outside the loop.
      continue d
    }
    [] => ()
  }
  // end example
  ctx.snapshot(filename="snapshot")
}
