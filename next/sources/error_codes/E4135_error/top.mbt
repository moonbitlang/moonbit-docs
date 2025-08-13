trait ByteSize { byte_size() -> Int}
impl ByteSize for Byte with byte_size() { 1 }
impl ByteSize for Int with byte_size() { 4 }

trait WordSize { word_size() -> Int }
impl WordSize for Float with word_size() { 1 }
impl WordSize for Double with word_size() { 2 }

trait Size { size(Self) -> Int }

impl[T : ByteSize] Size for Array[T] with size(self) {
  self.length() * T::byte_size()
}

impl[T : WordSize] Size for Array[T] with size(self) {
//<~~~~~~~~~~~~~~~
// Error: Inconsistent `impl` of trait Size for Array at 11:1 and 15:1:
//   type parameters of implementations have different constraints
  self.length() * T::word_size() * 4
}