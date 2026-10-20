///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let count = 2
  for remaining = count; remaining >= 0; remaining = remaining - 1 {
    println(remaining)
  }
  // end example
  ctx.snapshot(filename="snapshot_0")
}
