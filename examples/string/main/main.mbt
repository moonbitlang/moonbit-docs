fn init {
  let (arr, len) = @lib.split("a.b.c.e.f.g.h.i.j.k.l.m.n", '.')
  var index = 0
  // let l = arr.length()
  while index < len {
    println(arr[index])
    index = index + 1
  }

  match @lib.sub_string("Hello World", 3, 7) {
    Some(v) => println(v)
    None => println("Not found")
  }

  match @lib.index_of("Hello World", "Wo") {
    Some(v) => println(v)
    None => println("Not found")
  }

  match @lib.last_index_of("Hello World World Hello", "Wo") {
    Some(v) => println(v)
    None => println("Not found")
  }

  match @lib.contains("Hello World", "Wo") {
    true => println("Contains")
    false => println("Not found")
  }

  let arr = @lib.to_char_array("HelloWorld")
  var index = 0
  let l = arr.length()
  while index < l {
    println(arr[index])
    index = index + 1
  }

  match @lib.char_at("abcde", 4) {
    Some(v) => println(v)
    None => println("Not found")
  }
  println(@lib.trim("   abcde   ", ' '))
}
