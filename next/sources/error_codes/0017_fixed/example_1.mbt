///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let a : StringView = "asdf"
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
