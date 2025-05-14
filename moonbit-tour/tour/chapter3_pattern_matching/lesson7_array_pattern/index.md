# Array Pattern

An array pattern is a sequence of patterns enclosed in `[]` that matches an array.

You can use `..` to match the rest of the array at the start, end, or middle elements of the array.

In an array pattern, the `..` part can be bound to a new variable via an *alias pattern*. The type of that variable is `@array.View`. The `sum` function uses this feature to calculate the sum of the array recursively. 
