///|
priv struct Bag {}

///|
fn Bag::iter(_self : Bag) -> Iter[Int32] {
  [1, 2, 3].iter()
}

///|
fn sum(bag : Bag) -> Int32 {
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
