pub let pi = 3.141592653589793

pub let tau = 6.283185307179586

pub let e = 2.718281828459045

pub let int_min = -2147483648

pub let int_max = 2147483647

pub fn max[T : Compare](a : T, b : T) -> T {
  if a.compare(b) >= 0 {
    return a
  }
  return b
}

pub fn min[T : Compare](a : T, b : T) -> T {
  if a.compare(b) >= 0 {
    return b
  }
  return a
}

pub fn abs_int(n : Int) -> Int {
  if n.compare(0) >= 0 {
    return n
  }
  return -n
}

pub fn factorial(n : Int) -> Option[Int] {
  fn factorial_helper(n : Int, acc : Int) -> Option[Int] {
    match n {
      0 | 1 => Some(acc)
      _ =>
        if acc * n < 0 {
          None
        } else {
          factorial_helper(n - 1, acc * n)
        }
    }
  }

  factorial_helper(n, 1)
}

pub fn parse_int(s : String) -> Option[Int] {
  let char_0 = 0x30
  let char_u_a = 0x41
  let char_a = 0x61
  var index = 0
  var is_negative = false
  var result_digit = 0
  if s[index] == '-' {
    index = index + 1
    is_negative = true
  }
  let radix = if s[index] == '0' && (s[index + 1] == 'x' || s[index + 1] == 'X') {
    index = index + 2
    16
  } else if s[index] == '0' && (s[index + 1] == 'o' || s[index + 1] == 'O') {
    index = index + 2
    8
  } else if s[index] == '0' && (s[index + 1] == 'b' || s[index + 1] == 'B') {
    index = index + 2
    2
  } else {
    10
  }
  while index < s.length() {
    let c = s[index]
    if c == '_' {
      index = index + 1
      continue
    }
    let digit = if c.compare('0') >= 0 && c.compare('9') <= 0 {
      c.to_int() - char_0
    } else if c.to_int() - char_a < 26 {
      c.to_int() - char_a + 10
    } else if c.to_int() - char_u_a < 26 {
      c.to_int() - char_u_a + 10
    } else {
      break
    }
    result_digit = if is_negative {
      result_digit * radix - digit
    } else {
      result_digit * radix + digit
    }
    if not(is_negative) && result_digit < 0 || is_negative && result_digit > 0 {
      return None
    }
    index = index + 1
  }
  return Some(result_digit)
}

fn init {
  ()
}

