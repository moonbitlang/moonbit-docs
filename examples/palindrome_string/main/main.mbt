func init {
  let test1 = "abc"
  let test2 = "aba"
  let a = @lib.is_palindrome(test1)
  let b = @lib.is_palindrome(test2)
  if a {
    test1.print() // not print
  }
  if b {
    test2.print() // print "aba"
  }
}

