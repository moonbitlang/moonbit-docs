fn main {
  let draw : (Int) -> Int! = fn(luck : Int) -> Int {
    //                                         ^~~
    // Error: The return type of this anonymous function is expected include an
    // error type. Please add the error type to the return type annotation or
    // use `fn!` instead.
    if luck == 7 {
      return 42
    }
    fail!("Bad luck") // E4122 as well
  }
  try {
    println("Draw: \{draw!(7)}")
  } catch {
    error => println("Error: \{error}")
  }
}