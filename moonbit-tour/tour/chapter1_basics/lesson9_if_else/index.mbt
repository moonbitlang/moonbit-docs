fn fib(x : Int) -> Int {
  if x < 2 {
    x
  } else {
    fib(x - 1) + fib(x - 2)
  }
}

fn main {
  if 5 > 1 {
    println("5 is greater than 1")
  }
  println(fib(5))
  println(weekday(3))
}

fn weekday(x : Int) -> String {
  if x == 1 {
    "Monday"
  } else if x == 2 {
    "Tuesday"
  } else if x == 3 {
    "Wednesday"
  } else if x == 4 {
    "Thursday"
  } else if x == 5 {
    "Friday"
  } else if x == 6 {
    "Saturday"
  } else if x == 7 {
    "Sunday"
  } else {
    "Invalid day"
  }
}
