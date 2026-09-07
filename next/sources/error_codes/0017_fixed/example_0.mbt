///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let a : StringView = "asdf"
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
