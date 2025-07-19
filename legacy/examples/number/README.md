# Number
Use MoonBit to implement string tools.
## API
```
pub fn max[T : Compare](a : T, b : T) -> T
```
This function takes two values of type `T` and returns the maximum value between them. The type `T` must implement the Compare trait for comparison.

Parameters

- `a` (`T`): The first value.

- `b` (`T`): The second value.

Returns

- (`T`): The maximum value between `a` and `b`.
```
pub fn min[T : Compare](a : T, b : T) -> T
```
This function takes two values of type `T` and returns the minimum value between them. The type `T` must implement the Compare trait for comparison.

Parameters

- `a` (`T`): The first value.

- `b` (`T`): The second value.

Returns

- (`T`): The minimum value between `a` and `b`.
```
pub fn abs_int(n : Int) -> Int
```
This function calculates the absolute value of an integer.

Parameters

- `n` (`Int`): The integer value.

Returns

- (`Int`): The absolute value of `n`.

```
pub fn factorial(n : Int) -> Option[Int]
```
This function calculates the factorial of a non-negative integer `n`.

Parameters

- `n` (`Int`): The non-negative integer value.

Returns

- `Some(Int)`: The factorial of n if n is non-negative.

- `None`: If n is negative.
```
pub fn parse_int(s : String) -> Option[Int]
```
This function parses an integer from a string and returns it as an option. If the string does not represent a valid integer, it returns `None`.

Parameters

- `s` (`String`): The string containing the integer representation.

Returns

`Some(Int)`: The parsed integer if the string is a valid representation.

`None`: If the string is not a valid integer representation.