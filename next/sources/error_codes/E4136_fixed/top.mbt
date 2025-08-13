type Outer Inner

fn main {
  let outer : Outer = Inner::{ value: 1 }
  println(outer.value)
}