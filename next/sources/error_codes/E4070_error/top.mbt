pub fn my_abort(message : String) -> Unit = "%abort"
// Error: Unknown intrinsic: %abort

fn main {
  my_abort("Abort!")
}