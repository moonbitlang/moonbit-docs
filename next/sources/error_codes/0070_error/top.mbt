///|
struct Bag {}

///|
fn Bag::iterator(_self : Bag) -> Iter[Int] {
  [1, 2, 3].iter()
}

///|
fn sum(bag : Bag) -> Int {
  let mut total = 0
  for value in bag {
    total = total + value
  }
  total
}

///|
test {
  inspect(sum(Bag::{  }), content="6")
}
