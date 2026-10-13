///|
trait T {
  f(Self) -> Int32
}

///|
struct A(Int32) derive(T) // Error: Don't know how to derive trait T for type A
