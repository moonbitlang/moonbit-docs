# Pattern in let and match

There are two common places to use a pattern: `let` and `match`.

In this example, we define a `Resource` type that describes a file system.
The `Resource` can be a text file, an image, or a folder associated with more files.

## Pattern in let statement

In a `let` statement, the left side of `=` can be a pattern.
We know that `assets` is a folder so we just use `let Folder(top_level) = assets` to match it and extract the value into the immutable variable `top_level`.

You may notice that there is a partial match warning because the resource can also be `Image` or `TextFile`.
**Partial matches make the program more fragile: the pattern matching may fail in other cases and lead to the program aborting.**
Practically, the `match` expression is used more frequently than the `let` statement.

## Pattern in match expression

The `count` function traverses the input `res` recursively and returns the count of `Image` and `TextFile`, using a `match` expression.

Match expressions have *first match semantics*. They will try to find the first matching pattern sequentially from the first case to the last case and execute the corresponding matched expression. If no pattern matches, the program will abort.

The match expression has an `Int` return value because all the cases result in the same value type `Int`.

Patterns can be nested. If you don't care about the data associated with the enum constructor, you can use the *any pattern*, written as `_`, instead of introducing a new variable.
The underscore means that the value is discarded.
