trait Original {
  to_int(Self) -> Int
}

typealias Alias = Original

trait Trait: Alias {
  to_int(Self) -> Int
}