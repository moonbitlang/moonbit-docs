///|
fn main {
  let a = @immut/hashmap.of([(1, "a"), (2, "b"), (3, "c")])
  let b = a.add(4, "d")
  let c = @immut/sorted_map.from_iter(b.iter())
  println(c.keys())
}
