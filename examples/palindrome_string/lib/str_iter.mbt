/// Check if a given string is a palindrome.
///
/// This function takes a string as input and checks whether it is a palindrome or not.
/// A palindrome is a string that reads the same forwards and backwards.
///
/// @param {String} chars - The input string to be checked for palindrome.
/// @return {Bool} Returns `true` if the input string is a palindrome, otherwise `false`.
pub func is_palindrome(chars : String) -> Bool {
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

