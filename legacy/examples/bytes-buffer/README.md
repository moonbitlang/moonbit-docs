# Bytes-Buffer
## API
```moonbit
pub func Buffer::new(size : Int) -> Buffer
```
Creates a new buffer with the specified size.
```moonbit
pub func capacity(self : Buffer) -> Int
```
Returns the total capacity of the buffer.
```moonbit
pub func length(self : Buffer) -> Int
```
Returns the current length of the buffer.
```moonbit
pub func append_int(self : Buffer, value : Int)
```
Appends an integer value to the buffer.
```moonbit
pub func truncate(self : Buffer, another: Buffer)
```
Truncates the buffer and replaces its content with the content of another buffer.
```moonbit
pub func clear(self : Buffer)
```
Clears the content of the buffer.
```moonbit
pub func reset(self : Buffer, capacity : Int)
```
Resets the buffer with a new capacity.
```moonbit
pub func to_bytes(self : Buffer) -> Bytes
```
Converts the buffer content to bytes.
```moonbit
pub func bytes_to_int(bytes : Bytes, start : Int) -> Int
```
Converts a section of bytes to an integer.

