type MyInt Int

fn increment(self : MyInt) -> MyInt {
  MyInt(self._ + 1)
}

fn MyInt::println(x : MyInt) -> Unit {
  println("MyInt(\{x._})")
}

fn main {
  let x = MyInt(39)
  let y = x.increment() // call method via dot syntax
  let z = increment(y) // `fn increment(..)` can be called directly
  let w = MyInt::increment(z) // call methods using qualified syntax
  w.println()
  MyInt::println(w) // `fn MyInt::println` cannot be called via `println(..)` directly
}
