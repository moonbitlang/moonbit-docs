type A Int

fn A::op_add(self : A, other : A, opt? : A) -> A {
  //  ^~~~~~
  // Error: overloaded operator "op_add" should accept 2 arguments, but it accepts 3 arguments
  let opt = match opt {
    None => 0
    Some(opt) => opt._
  }
  return self._ + other._ + opt
}