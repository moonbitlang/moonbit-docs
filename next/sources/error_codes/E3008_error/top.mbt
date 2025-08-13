fn main {
  let array = [1, 2, 3, 4, 5]
  let [fst, .., .., snd] = array
  //            ^^
  // Error: At most one `..` is allowed in array pattern.
}