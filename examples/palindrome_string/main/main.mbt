test {
  let test1 = "abc"
  let test2 = "aba"
  let test3 = "上海自来水来自海上"
  (test1 |> @lib.is_palindrome |> @test.is_false)!
  (test2 |> @lib.is_palindrome |> @test.is_true)!
  (test3 |> @lib.is_palindrome |> @test.is_true)!
}

