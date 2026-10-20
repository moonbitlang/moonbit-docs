///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let a : StringView = "asdf"
  let b = a
  for a = a; a is [_, .. d]; a = d {
    println(b)
  }
  // end example
  ctx.snapshot(filename="snapshot_1")
}
