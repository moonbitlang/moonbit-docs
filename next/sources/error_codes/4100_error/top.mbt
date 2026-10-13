///|
pub struct Original(Int32)

///|
type Alias = Original

///|
pub trait Trait: Alias {
  //         ^~~~~
  // Error: The type Alias is not a trait
}
