# Guard Condition

In a `match` expression, you can add extra conditions to a pattern on the left of `=>` using the `if` keyword. This feature is called a *guard condition*. A guard condition allows you to refine the matching process by adding additional boolean expressions that must evaluate to `true` for the pattern to be considered a match.

In function `validate`, we use a guard condition to ensure the string in the option is not empty:

- If the option is `Some(path)` and `path` is not an empty string, the `match` expression evaluates to `true`.

- If the option is `Some(path)` but `path` is an empty string, the pattern guard fails, and the second case with the wildcard pattern `_` is matched instead. The `match` expression evaluates to `false`.

- If the option is `None`, the wildcard pattern `_` is matched, and the `match` expression evaluates to `false`.


