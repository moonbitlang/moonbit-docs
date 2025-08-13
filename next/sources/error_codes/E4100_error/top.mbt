type Original Int

typealias Alias = Original

trait Trait: Alias {
  //         ^~~~~
  // Error: The type Alias is not a trait
}