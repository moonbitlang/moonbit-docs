///|
pub fn safe_add(i : Int, j : Int) -> Int! {
  let signum_i = i & 0x80000000
  let signum_j = j & 0x80000000
  let result = i + j
  if signum_i != signum_j {
    result
  } else {
    let result_signum = result & 0x80000000
    if result_signum != signum_i {
      fail!("overflow")
    } else {
      result
    }
  }
}

///|
fn main {
  let a = try {
    safe_add!(1, 2)
  } catch {
    _ => panic()
  }
  try {
    let result = safe_add!(@int.max_value, @int.max_value)

  } catch {
    Failure(error_message) => println(error_message)
    _ => panic()
  }
  let result = safe_add?(@int.max_value, @int.max_value)

}
