///|
trait T {
  f(Self) -> Int32
}

///|
#derive(T)
struct A(Int32) // Error: Don't know how to derive trait T for type A
