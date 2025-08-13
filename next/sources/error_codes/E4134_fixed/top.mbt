fn main {
  let draw : (Int) -> Int! = fn(luck : Int) -> Int! {
    if luck == 7 {
      return 42
    }
    fail!("Bad luck")
  }
  try {
    println("Draw: \{draw!(7)}")
  } catch {
    error => println("Error: \{error}")
  }
}