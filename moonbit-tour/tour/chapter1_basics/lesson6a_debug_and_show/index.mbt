///|
fn main {
  let name : String = "MoonBit"
  let emails = [
    "moonbit@example.email",
    "moonbit-community@example.email",
    "moonbit-x@example.email",
  ]

  // Interpolation is useful for values with a display format.
  println("name: \{name}")

  // Use to_repr when you want to inspect a data structure.
  println("emails: \{to_repr(emails)}")

  // debug(x) is shorthand for println("\{to_repr(x)}").
  debug(emails)
}
