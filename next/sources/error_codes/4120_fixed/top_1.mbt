///|
pub fn materialize_error() -> Result[Unit, ExampleError] {
  try {
    may_raise_error(42)
    Ok(())
  } catch {
    error => Err(error)
  }
}
