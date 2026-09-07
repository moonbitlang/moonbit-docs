///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let count = 2
  loop count {
    _..<0 => break
    count => {
      println(count)
      continue count - 1
    }
  }
  // end example
  ctx.snapshot(filename="snapshot_0")
}
