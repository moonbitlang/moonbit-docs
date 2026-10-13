///|
const A : Int32 = 1

///|
const B : Int32 = A + 1

///|
type T1 = Int32

///|
type T2 = T1

///|
fn use_declarations(value : T2) -> Int32 {
  value + B
}

///|
test {
  assert_eq(use_declarations(A), 3)
}
