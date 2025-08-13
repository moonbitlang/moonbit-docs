fn main {
  let a = @a.T::new()
  a.value = 3 // Error: Cannot modify a read-only field: value
}