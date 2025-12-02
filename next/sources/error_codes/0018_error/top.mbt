///|
test (ctx : @test.Test) {
  let println = ctx.writeln(_)
  // start example
  let count = 2
  loop count {
    _..<0 => break
    _ => println(count)
  }
  // end example
  ctx.snapshot(filename="snapshot")
}
