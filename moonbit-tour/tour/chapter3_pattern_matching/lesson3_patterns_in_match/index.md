# Patterns in `match` expression

In this example, we define a `Resource` type that describes a file system. The `Resource` can be a text file, an image, or a folder associated with more files.

The `count` function traverses the input `res` recursively and returns the count of `Image` and `TextFile`, using a `match` expression.

Match expressions have *first match semantics*. They will try to find the first matching pattern sequentially from the first case to the last case and execute the corresponding matched expression. If no pattern matches, the program will abort.

The match expression has an `Int` return value because all the cases result in the same value type `Int`.

Patterns can be nested. If you don't care about the data associated with the enum constructor, you can use the *any pattern*, written as `_`, instead of introducing a new variable.
