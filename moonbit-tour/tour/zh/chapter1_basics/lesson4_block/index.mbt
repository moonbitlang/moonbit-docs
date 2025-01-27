fn main {
  let a = 100

  {
    let mut a = 0
    println("checkpoint 1")
    a = a + 1
  }

  println("checkpoint 2")
  println(f())
}

fn f() -> Int {
  let b = 3.14

  let result = {
    let b = 1
    println("checkpoint 3")
    b + 5 
  }

  result // same as `return result` here
}


