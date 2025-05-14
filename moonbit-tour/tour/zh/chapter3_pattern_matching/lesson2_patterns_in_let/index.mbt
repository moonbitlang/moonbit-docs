fn main {
  f([1, 2, 3])
  f([1, 2])
}

fn f(array : Array[Int]) -> Unit {
  let [a, b, c] = array // warning as error
  println("a:\{a}, b:\{b}, c:\{c}")
}
