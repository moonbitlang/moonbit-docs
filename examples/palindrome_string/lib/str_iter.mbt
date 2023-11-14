pub fn is_palindrome(chars : String) -> Bool {
  let n = chars.length()
  var i = 0
  while i < n / 2 {
    if chars[i] != chars[n - i - 1] {
      return false
    }
    i = i + 1
  }
  return true
}

