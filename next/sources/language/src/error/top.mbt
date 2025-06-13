// start error 1
suberror E1 Int // error type E1 has one constructor E1 with an Int payload

suberror E2 // error type E2 has one constructor E2 with no payload

suberror E3 {
  A // error type E3 has three constructors like a normal enum type
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

  fn g() -> Unit raise {
    ...
  }

  fn h() -> Unit raise Error {
    ...
  }
  // end error 3

}

// start error 4
suberror IntError Int

fn h(f : (Int) -> Int raise, x : Int) -> Unit {
  ...
}

fn g() -> Unit {
  let _ = h(fn! { x => raise IntError(x) }, 0)
  let _ = h(fn(x) raise { raise IntError(x) }, 0)

}
// end error 4

// start error 5
// Result::unwrap_or_error
fn[T, E : Error] unwrap_or_error(result : Result[T, E]) -> T raise E {
  match result {
    Ok(x) => x
    Err(e) => raise e
  }
}
// end error 5

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
  div(x, y) + div(x, y) // Rethrow the error if `div` raised an error
}
// end error 7

// start error 8
test {
  let res = try? (div(6, 0) * div(6, 3))
  inspect(
    res,
    content=
      #|Err("division by zero")
    ,
  )
}
// end error 8

test "error 9" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start error 9
  try div(42, 0) catch {
    DivError(s) => println(s)
  } else {
    v => println(v)
  }
  // end error 9
  t.snapshot(filename="error_9")
}

fn error() -> Unit {
  // start error 10
  println(div(42, 0)) catch {
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
    _ => ...
  }
  // end error 13
  // start error 14
  try {
    f1()
    f2()
  } catch {
    E1(_) => ...
    e => raise e
  }
  // end error 14
}

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

test {
  let array = [1, 2, 3]
  let res = try? map_with_polymorphism(array, fn(x) { x + 1 })
  let res2 = try? map_with_polymorphism(array, fn(x) { fail("") })
  guard res2 is Err(_)
}
// end error polymorphism 2
