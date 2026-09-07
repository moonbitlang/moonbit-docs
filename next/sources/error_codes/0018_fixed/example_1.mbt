///|
test (ctx : @test.Test) {
  let println = value => ctx.writeln(value)
  // start example
  let count = 2
  match count {
    _..<0 => ()
    _ => println(count)
  }
  // end example
  ctx.snapshot(filename="snapshot_1")
}
