# Buffer
## API
Creates a new instance of the Buffer type with the specified initial capacity. The capacity determines the initial size of the buffer to store elements of type T. The type T must implement the Default trait to provide a default value.
```moonbit
Buffer::new[T : Default](capacity : Int) -> Buffer[T]
```
Returns the current capacity of the buffer. The capacity represents the maximum number of elements that the buffer can hold without resizing.
```moonbit
capacity[T](self : Buffer[T]) -> Int
```
Returns the current number of elements stored in the buffer. This method provides the actual count of elements present in the buffer.
```moonbit
length[T](self : Buffer[T]) -> Int
```
Appends an element of type T to the end of the buffer. If the buffer is at its capacity, it may be automatically resized to accommodate the new element.
```moonbit
append[T : Default](self : Buffer[T], value : T)
```
Truncates the current buffer and copies the contents of another buffer another into it. The original capacity of the buffer remains unchanged.
```moonbit
truncate[T : Default](self : Buffer[T], another : Buffer[T])
```
Clears all elements from the buffer and resets its length to zero. The capacity remains unchanged.
```moonbit
clear[T : Default](self : Buffer[T])
```
Resets the buffer by clearing its contents and setting its capacity to the specified value. This is useful when you want to reuse an existing buffer with a different capacity.
```moonbit
reset[T : Default](self : Buffer[T], capacity : Int)
```
Prints the contents of the buffer to the standard output using the Show trait. The Show trait must be implemented for type T in order to use this method.
```moonbit
println[T : Show](self: Buffer[T])
```
