///|
test (ctx : @test.T) {
  let println = ctx.writeln(_)
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
