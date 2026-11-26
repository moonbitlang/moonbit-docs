///|
pub(all) struct Scanner[T] {
  input : StringView
  mut cursor : Int32
  tag : T
}

///|
impl[T : Show] @lexbuf.Scannable for Scanner[T] with fn scan_input(self) {
  self.input
}

///|
impl[T : Show] @lexbuf.Scannable for Scanner[T] with fn scan_cursor(self) {
  self.cursor
}

///|
impl[T : Show] @lexbuf.Scannable for Scanner[T] with fn set_scan_cursor(self, cursor) {
  self.cursor = cursor
}

///|
pub fn scan_word(target : Scanner[Int32]) -> Bool {
  lexscan target {
    re"^[a-z]+" => true
    _ => false
  }
}
