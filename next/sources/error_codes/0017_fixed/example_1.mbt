///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let a : StringView = "asdf"
  let b = a
  for remaining = a {
    match remaining {
      [_, .. d] => {
        println(b)
        continue d
      }
      [] => break
    }
  }
  // end example
  ctx.snapshot(filename="snapshot_1")
}
