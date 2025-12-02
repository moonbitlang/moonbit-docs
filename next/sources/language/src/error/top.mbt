// start error 1
suberror E1 Int // error type E1 has one constructor E1 with an Int payload

suberror E2 // error type E2 has one constructor E2 with no payload

suberror E3 { // error type E3 has three constructors like a normal enum type
  A
  B(Int, x~ : String)
  C(mut x~ : String, Char, y~ : Bool)
}
// end error 1

// start error 2
suberror DivError String

fn div(x : Int, y : Int) -> Int raise DivError {
  if y == 0 {
    raise DivError("division by zero")
  }
  x / y
}
// end error 2

impl Show for DivError with output(self, logger) {
  match self {
    DivError(e) => Show::output(e, logger)
  }
}

let signature : Unit = {
  // start error 3
  fn f() -> Unit raise {
    ...
  }

  fn g() -> Unit raise Error {
    let h : () -> Unit raise = fn() raise { fail("fail") }
    ...
  }
  // end error 3
}

// start error 5
// Result::unwrap_or_error
fn[T, E : Error] unwrap_or_error(result : Result[T, E]) -> T raise E {
  match result {
    Ok(x) => x
    Err(e) => raise e
  }
}
// end error 5

// start noraise
fn add(a : Int, b : Int) -> Int noraise {
  a + b
}
// end noraise

test {
  (Ok(1) : Result[Int, Error]).unwrap_or_error() |> ignore
}

// start error 6
fn f(e : Error) -> Unit {
  match e {
    E2 => println("E2")
    A => println("A")
    B(i, x~) => println("B(\{i}, \{x})")
    _ => println("unknown error")
  }
}
// end error 6

// start error 7
fn div_reraise(x : Int, y : Int) -> Int raise DivError {
  div(x, y) // Rethrow the error if `div` raised an error
}
// end error 7

// start error 8
test {
  let res = try? (div(6, 0) * div(6, 3))
  inspect(
    res,
    content=(
      #|Err("division by zero")
    ),
  )
}
// end error 8

test "error 9" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // start error 9
  try div(42, 0) catch {
    DivError(s) => println(s)
  } noraise {
    v => println(v)
  }
  // end error 9
  t.snapshot(filename="error_9")
}

fn error() -> Unit {
  // start error 10
  try { println(div(42, 0)) } catch {
    _ => println("Error")
  }
  // end error 10

  // start error 11
  let a = div(42, 0) catch { _ => 0 }
  println(a)
  // end error 11
}

fn catch_() -> Unit raise {
  // start error 13
  fn f1() -> Unit raise E1 {
    ...
  }

  fn f2() -> Unit raise E2 {
    ...
  }

  try {
    f1()
    f2()
  } catch {
    E1(_) => ...
    E2 => ...
    e => raise e
  }
  // end error 13
}

// start error 14
fn remainder(a : Int, b : Int) -> Int raise DivError {
  if b == 0 {
    raise DivError("division by zero")
  }
  let div = try! div(a, b)
  a - b * div
}
// end error 14

// start custom error conversion
suberror CustomError UInt

test {
  let e : Error = CustomError(42)
  guard e is CustomError(m)
  assert_eq(m, 42)
}
// end custom error conversion

// start error polymorphism
fn[T] map(array : Array[T], f : (T) -> T raise) -> Array[T] raise {
  let mut res = []
  for x in array {
    res.push(f(x))
  }
  res
}
// end error polymorphism

// start error polymorphism 2
fn[T] map_with_polymorphism(
  array : Array[T],
  f : (T) -> T raise?
) -> Array[T] raise? {
  let mut res = []
  for x in array {
    res.push(f(x))
  }
  res
}

fn[T] map_without_error(
  array : Array[T],
  f : (T) -> T noraise,
) -> Array[T] noraise {
  map_with_polymorphism(array, f)
}

fn[T] map_with_error(array : Array[T], f : (T) -> T raise) -> Array[T] raise {
  map_with_polymorphism(array, f)
}
// end error polymorphism 2
