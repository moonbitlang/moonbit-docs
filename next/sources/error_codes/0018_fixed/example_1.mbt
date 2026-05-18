///|
test (ctx : @test.Test) {
  let println = ctx.writeln(_)
  // start example
  let count = 2
  match count {
    _..<0 => ()
    _ => println(count)
  }
  // end example
  ctx.snapshot(filename="snapshot_1")
}
