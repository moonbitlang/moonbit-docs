test {
  @test.is_true(@lib.is_alpha('a'))!
  @test.is_false(@lib.is_alpha('3'))!
  @test.is_true(@lib.is_numeric('1'))!
  @test.is_false(@lib.is_numeric('b'))!
  @test.is_true(@lib.is_alphanumeric('a'))!
  @test.eq(@lib.to_lower('H'), 'h')!
  @test.eq(@lib.to_upper('c'), 'C')!
  @test.is_true(@lib.is_whitespace(' '))!
  @test.eq(@lib.next('Z'), Some('['))!
  @test.eq(@lib.prev('A'), Some('@'))!
}
