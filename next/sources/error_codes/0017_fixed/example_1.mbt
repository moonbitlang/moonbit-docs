///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let b : StringView = "asdf"
  for a = b; a is [_, .. d]; a = d {
    println(b)
  }
  // end example
  ctx.snapshot(filename="snapshot_1")
}
