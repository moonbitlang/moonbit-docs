///|
test (ctx : @test.T) {
  let println = ctx.writeln(_)
  // start example
  let a : @string.View = "asdf"
  loop a {
    [_, .. d] as a => {
      println(a)
      continue d
    }
    [] => ()
  }
  // end example
  ctx.snapshot(filename="snapshot_0")
}
