///|
const A : Int = 1

///|
const B : Int = A + 1

///|
type T1 = Int

///|
type T2 = T1

///|
fn use_declarations(value : T2) -> Int {
  value + B
}

///|
test {
  assert_eq(use_declarations(A), 3)
}
