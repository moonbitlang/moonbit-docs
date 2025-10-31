///|
/// Extend the `@sorted_set.SortedSet` type with local method `add_range`.
/// 
/// The `SortedSet` are defiend in `moonbitlang/core/sorted_set`, you can find 
/// the API docs in https://mooncakes.io/docs/moonbitlang/core/sorted_set
fn @sorted_set.SortedSet::add_range(self : Self[Int], l : Int, r : Int) -> Unit {
  for i in l..=r {
    self.add(i)
  }
}

///|
fn main {
  let set = @sorted_set.new()
  set.add_range(1, 10)
  set.add_range(15, 20)
  println(set)
}
