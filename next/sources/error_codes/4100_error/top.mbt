///|
pub struct Original(Int)

///|
type Alias = Original

///|
pub trait Trait: Alias {
  //         ^~~~~
  // Error: The type Alias is not a trait
}
