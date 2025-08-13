trait T {
  f(Self) -> Int
}

// Remove derive(T)
type A Int

impl T for A with f(self : A) -> Int {
  0
}