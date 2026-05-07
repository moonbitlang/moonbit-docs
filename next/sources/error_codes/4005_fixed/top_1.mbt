///|
priv trait LoudAnimal {
  make_sound(Self) -> String
  make_loud_sound(Self) -> String // Use a different name for different behavior
}

///|
priv struct Cat {}

///|
impl LoudAnimal for Cat with make_sound(_) {
  "meow"
}

///|
impl LoudAnimal for Cat with make_loud_sound(_) {
  "MEOW"
}

///|
test {
  let cat = Cat::{  }
  inspect(cat.make_sound(), content="meow")
  inspect(cat.make_loud_sound(), content="MEOW")
}
