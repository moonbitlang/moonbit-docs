trait T {
  f(Self) -> Int
}

type A Int derive(T) // Error: Don't know how to derive trait T for type A