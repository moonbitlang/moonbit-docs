///|
fn main {
  let a = @immut/hashset.from_array([5, 4, 3, 2, 1])
  let b = @immut/sorted_set.from_array([5, 4, 3, 2, 1])
  let arraya = a.iter().collect()
  let arrayb = b.iter().collect()
  let c = a.add(6)
  let d = b.add(6)
  let except_one = d.remove_min()
  println(to_repr(d))
}
