///|
trait T {
  f(Self) -> Int
}

///|
struct A(Int) derive(T) // Error: Don't know how to derive trait T for type A
