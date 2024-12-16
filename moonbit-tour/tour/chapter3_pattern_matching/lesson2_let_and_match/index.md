# Pattern in let and match

There are two common place to use pattern: let and match.

We defined a `Resource` type, it describes a file system. The `Resource` can be a text file, an image, or a folder associated with more files.

## Pattern in let statement

In a let statement, the left side of `=` can be a pattern, we known that assets is a folder so just use `let Folder(top_level) = assets` to match it and extract the inside map. 

You may notice that there is a partial match warning because the resource can also be `Image` or `TextFile`. **Partial match make the program more fragile: the pattern matching will fail in other cases and lead to the program aborting.** Practically, the match expression is used more frequently.

## Pattern in match expression

The `count` function traverse the input `res` recursively and return the count of `Image` and `TextFile`, using match expression. 

Match expressions have *first match semantics*. They will try to find the first matching pattern from the first case to the last case and execute the corresponding expression. If no pattern matches, the program will abort.

The match expression has a `Int` return value because all the case result in same value type `Int`.

Patterns can be nested. If you don't care about the data associated with the enum constructor, you can use the *any pattern*, written as `_`, instead of introducing a new variable. It means discarding that value.

