///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let a : StringView = "asdf"
  for a = a; a is [_, .. d]; a = d {
    println(a)
  }
  // end example
  ctx.snapshot(filename="snapshot_0")
}
