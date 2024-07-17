# String

Use MoonBit to implement string tools.

## API
Split a string, and return an array of string split and the length of the array.
```
split(String, Char) -> (Array[String], Int)
```
Get the substring of a string from start to end.
```
sub_string(String, start: Int, end: Int) -> Option[String]
```
Remove the character at the start and end.
```
trim(String, Char) -> String
```
Get the position of the first match.
```
index_of(s: String, pattern: String) -> Option[Int]
```
Get the position of the last match.
```
last_index_of(s: String, pattern: String) -> Option[Int]
```
Determine whether string s contains string sub. 
```
contains(s: String, sub: String) -> Bool
```
Return a char at the position.
```
char_at(String, position: Int) -> Option[Char]
```
Convert a string to a char array.
```
to_char_array(String) -> Array[Char]
```
Create an iterator for string.
```
iter(String) -> Iterator
next(Iterator) -> Option[Char]
```