///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let a : StringView = "asdf"
  for remaining = a {
    match remaining {
      [_, .. d] => {
        println(remaining)
        continue d
      }
      [] => break
    }
  }
  // end example
  ctx.snapshot(filename="snapshot_0")
}
