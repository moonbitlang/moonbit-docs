enum Status {
  Done(Unit)
  Pending
}

fn main {
  let status = Done(())
}