fn outer_sum(array : Array[Int32]) -> Int32 {
  let [fst, .., .., snd] = array
  fst + snd
}

test {
  inspect(outer_sum([1, 2, 3, 4, 5]), content="6")
}
