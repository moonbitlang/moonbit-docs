///|
test (ctx : @test.T) {
  let println = ctx.writeln(_)
  // start example
  let a : @string.View = "asdf"
  let b = a
  loop a {
    [_, .. d] => {
      println(b)
      continue d
    }
    [] => ()
  }
  // end example
  ctx.snapshot(filename="snapshot_1")
}
