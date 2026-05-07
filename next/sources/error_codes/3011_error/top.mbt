const N = 4

fn assign_const() -> Int {
  N = 5 // Error: Invalid left value for assignment.
  N
}

test {
  inspect(assign_const(), content="5")
}
