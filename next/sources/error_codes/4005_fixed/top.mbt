///|
priv trait Animal {
  make_sound(Self) -> String // Only declare the method once
}

///|
priv struct Dog {}

///|
impl Animal for Dog with make_sound(_) {
  "woof"
}

///|
fn[T : Animal] describe(animal : T) -> String {
  animal.make_sound()
}

///|
test {
  let dog = Dog::{  }
  inspect(describe(dog), content="woof")
}
