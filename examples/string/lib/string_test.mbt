test {
  let arr = split("a.b.c.e.f.g.h.i.j.k.l.m.n", '.')
  @test.eq(
    arr,
    ["a", "b", "c", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"],
  )!
  inspect(sub_string("Hello World", 3, 7), content="Some(lo W)")!
  ("Hello World" |> index_of("Wo") |> @test.eq(Some(6)))!
  ("Hello World World Hello"
  |> last_index_of("Wo")
  |> @test.eq(Some(12)))!
  @test.is_true(contains("Hello World", "Wo"))!
  let arr = to_char_array("HelloWorld")
  @test.eq(arr, ['H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd'])!
  @test.eq(char_at("abcde", 4), Some('e'))!
  @test.eq(trim("   abcde   ", ' '), "abcde")!
}
