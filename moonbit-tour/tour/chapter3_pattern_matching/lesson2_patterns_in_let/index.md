# Patterns in `let` statement

In a `let` statement, the left side of `=` can be a pattern to match against the value on the right side. If the pattern cannot be matched, the program will abort.

You may notice a partial match warning error. This occurs because the array might contain a different number of elements than expected, but the `let` statement only handles the case where the array contains exactly three elements. This is referred to as a partial match. **Partial matches make the program more fragile: the pattern matching may fail in other cases, leading to the program aborting.** By default, partial match warnings are treated as errors to help prevent potential runtime issues.

Practically, the `match` expression is used more frequently than the `let` statement.


