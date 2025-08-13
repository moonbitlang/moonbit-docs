fn f(input : Int?) -> Int {
  match input {
    Some(_..<0) => abort("Invalid input")
    _ => ()
  }
  3
}
