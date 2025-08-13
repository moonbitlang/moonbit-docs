enum Status {
  Done
  Pending
}

fn main {
  let status = Done() // Error: constructor without payload cannot be called with ()
}