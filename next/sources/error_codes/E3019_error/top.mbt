fn main {
  match 0 {
    0..=_ => println("Big than or equal to 0")
    //  ^
    // Error: Inclusive range pattern `a..=b` cannot have `_` as upper bound
    _ => println("Less than 0")
  }
}