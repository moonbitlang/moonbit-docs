test {
  let arr = split("a.b.c.e.f.g.h.i.j.k.l.m.n", '.')
  @assertion.assert_eq(
    arr,
    @vec.Vec::["a", "b", "c", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"],
  )?
  inspect(sub_string("Hello World", 3, 7), ~content="Some(lo W)")?
  ("Hello World" |> index_of("Wo") |> @assertion.assert_eq(Some(6)))?
  ("Hello World World Hello" |> last_index_of("Wo") |> @assertion.assert_eq(Some(12)))?
  @assertion.assert_true(contains("Hello World", "Wo"))?
  let arr = to_char_array("HelloWorld")
  @assertion.assert_eq(arr, ['H', 'e', 'l', 'l', 'o', 'W', 'o', 'r', 'l', 'd'])?
  @assertion.assert_eq(char_at("abcde", 4), Some('e'))?
  @assertion.assert_eq(trim("   abcde   ", ' '), "abcde")?
}
