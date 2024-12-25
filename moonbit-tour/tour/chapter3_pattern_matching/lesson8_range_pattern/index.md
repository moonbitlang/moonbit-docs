# Range Pattern

For consecutive values, using the previously introduced *or-patterns* can be somewhat cumbersome. To address this issue, we can use *range patterns*. *Range patterns* can match values within a specified range.


Recall the syntax we learned in Chapter 1:

- `start..<end` range is inclusive of the start value and exclusive of the end value.
- `start..=end` range is inclusive of both the start and end values.


Range patterns support built-in integer-like types, such as `Byte`, `Int`, `UInt`, `Int64`, `UInt64`, and `Char`.

