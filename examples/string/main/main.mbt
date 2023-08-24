func println(self : String) {
  self.print()
  "\n".print()
}

func println(self : Int) {
  self.print()
  "\n".print()
}

func println(self : Char) {
  self.print()
  "\n".print()
}

func init {
  let (arr, len) = @lib.split("a.b.c.e.f.g.h.i.j.k.l.m.n", '.')
  var index = 0
  // let l = arr.length()
  while index < len {
    arr[index].println()
    index = index + 1
  }

  match @lib.sub_string("Hello World", 3, 7) {
    Some(v) => v.println()
    None => "Not found".println()
  }

  match @lib.index_of("Hello World", "Wo") {
    Some(v) => v.println()
    None => "Not found".println()
  }

  match @lib.last_index_of("Hello World World Hello", "Wo") {
    Some(v) => v.println()
    None => "Not found".println()
  }

  match @lib.contains("Hello World", "Wo") {
    true => "Contains".println()
    false => "Not found".println()
  }

  let arr = @lib.to_char_array("HelloWorld")
  var index = 0
  let l = arr.length()
  while index < l {
    arr[index].println()
    index = index + 1
  }

  match @lib.char_at("abcde", 4) {
    Some(v) => v.println()
    None => "Not found".print()
  }
  @lib.trim("   abcde   ", ' ').println()
}
