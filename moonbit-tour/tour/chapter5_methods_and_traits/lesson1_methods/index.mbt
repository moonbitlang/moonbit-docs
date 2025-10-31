struct MyInt (Int) 

fn MyInt::increment(self : Self) -> Self {
  let MyInt(x) = self
  MyInt(x + 1)
}

fn main {
  let x = MyInt(39)
  let y = x.increment()       // call method via dot syntax
  let z = MyInt::increment(y) // call methods using qualified syntax
  println(z.0)
}
