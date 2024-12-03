fn a() -> Int {
  let x = 1
  let y = 1
  let expr1 = 1
  let expr2 = 1
  // start conditional expressions 1
  if x == y {
    expr1
  } else {
    expr2
  }
  // end conditional expressions 1
}

fn b() -> Unit {
  let x = 1
  let y = 1
  let expr1 = ()
  // start conditional expressions 2
  if x == y {
    expr1
  }
  // end conditional expressions 2
}

fn c() -> Unit {
  let size = 0
  // start conditional expressions 3
  let initial = if size < 1 { 1 } else { size }
  // end conditional expressions 3
}

test "while loop 1" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start while loop 1
  let mut i = 5
  while i > 0 {
    println(i)
    i = i - 1
  }
  // end while loop 1
  t.snapshot!(filename="while_loop_1")
}

test "while loop 2" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start while loop 2
  let mut i = 5
  while i > 0 {
    i = i - 1
    if i == 4 {
      continue
    }
    if i == 1 {
      break
    }
    println(i)
  }
  // end while loop 2
  t.snapshot!(filename="while_loop_2")
}

test "while loop 3" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start while loop 3
  let mut i = 2
  while i > 0 {
    println(i)
    i = i - 1
  } else {
    println(i)
  }
  // end while loop 3
  t.snapshot!(filename="while_loop_3")
}

test "while loop 4" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start while loop 4
  let mut i = 10
  let r = while i > 0 {
    i = i - 1
    if i % 2 == 0 {
      break 5
    }
  } else {
    7
  }
  println(r)
  // end while loop 4
  t.snapshot!(filename="while_loop_4")
}

test "while loop 5" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start while loop 5
  let mut i = 10
  let r = while i > 0 {
    i = i - 1
  } else {
    7
  }
  println(r)
  // end while loop 5
  t.snapshot!(filename="while_loop_5")
}

test "for loop 1" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start for loop 1
  for i = 0; i < 5; i = i + 1 {
    println(i)
  }
  // end for loop 1
  t.snapshot!(filename="for_loop_1")
}

fn d() -> Unit {
  // start for loop 2
  for i = 0, j = 0; i + j < 100; i = i + 1, j = j + 1 {
    println(i)
  }
  // end for loop 2
}

fn infinite_loop() -> Unit {
  // start for loop 3
  for i = 1; ; i = i + 1 {
    println(i)
  }
  for {
    println("loop forever")
  }
  // end for loop 3
}

test "for loop 4" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start for loop 4
  let sum = for i = 1, acc = 0; i <= 6; i = i + 1 {
    if i % 2 == 0 {
      println("even: \{i}")
      continue i + 1, acc + i
    }
  } else {
    acc
  }
  println(sum)
  // end for loop 4
  t.snapshot!(filename="for_loop_4")
}

fn e() -> Unit {
  // start for loop 5
  for x in [1, 2, 3] {
    println(x)
  }
  // end for loop 5
  // start for loop 6
  for k, v in { "x": 1, "y": 2, "z": 3 } {
    println(k)
    println(v)
  }
  // end for loop 6
  // start for loop 7
  for index, elem in [4, 5, 6] {
    let i = index + 1
    println("The \{i}-th element of the array is \{elem}")
  }
  // end for loop 7
}

test "for loop 7" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start for loop 7
  for index, elem in [4, 5, 6] {
    let i = index + 1
    println("The \{i}-th element of the array is \{elem}")
  }
  // end for loop 7
  t.snapshot!(filename="for_loop_7")
}

test "for loop 8" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start for loop 8
  let map = { "x": 1, "y": 2, "z": 3, "w": 4 }
  for k, v in map {
    if k == "y" {
      continue
    }
    println("\{k}, \{v}")
    if k == "z" {
      break
    }
  }
  // end for loop 8
  t.snapshot!(filename="for_loop_8")
}

// start for loop 9
test {
  fn sum(xs : @immut/list.T[Int]) -> Int {
    loop xs, 0 {
      Nil, acc => break acc // <=> Nil, acc => acc
      Cons(x, rest), acc => continue rest, x + acc
    }
  }

  assert_eq!(sum(Cons(1, Cons(2, Cons(3, Nil)))), 6)
}
// end for loop 9

fn f() -> Unit {
  let index = 1
  let len = 10
  // start guard 1
  guard index >= 0 && index < len else { abort("Index out of range") }
  // end guard 1
}

fn process(string : String) -> String {
  string
}

// start guard 2
enum Resource {
  Folder(Array[String])
  PlainText(String)
  JsonConfig(Json)
}

fn getProcessedText(
  resources : Map[String, Resource],
  path : String
) -> String!Error {
  guard let Some(PlainText(text)) = resources[path] else {
    None => fail!("\{path} not found")
    Some(Folder(_)) => fail!("\{path} is a folder")
    Some(JsonConfig(_)) => fail!("\{path} is a json config")
  }
  process(text)
}
// end guard 2

fn g() -> Unit {
  let condition = true
  let expr = Some(5)
  // start guard 3
  guard condition  // <=> guard condition else { panic() }
  guard let Some(x) = expr
  // <=> guard let Some(x) = expr else { _ => panic() }
  // end guard 3
}
