fn fibonacci(x : Int) -> Int {
  // assume x > 0
  match x {
    1 => 1
    2 => 2
    _ => fibonacci(x - 1) + fibonacci(x - 2)
  }
}

fn negate(x : Bool) -> Bool {
  match x {
    true => false
    false => true
  }
}

fn read(x : Char) -> Int? {
  match x {
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    _ => None
  }
}

fn contents(file : String) -> String? {
  match file {
    "README" => Some("# hello world")
    "hello.mbt" => Some("println(\"hello world\")")
    _ => None
  }
}

fn main {
  println("fib(5): \{fibonacci(5)}")
  println("negate(false): \{negate(false)}")
  println("read('2'): \{read('2')}, read('5'): \{read('5')}")
  println(contents("README"))
}
