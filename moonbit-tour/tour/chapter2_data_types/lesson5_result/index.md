# Result

Similar to `Option[Char]`, the enum `Result[Char, String]` represents a `Char` value that may or may not be present. If not present, it can contain an error message of type `String`.

- `Err("error message")` means the value is missing, and the error message is provided.
- `Ok('h')` is a wrapper that contains the value `'h'`.

The processing of `Option` and `Result` in examples so far is verbose and prone to bugs. To handle `Option` and `Result` values safely and cleanly, you can use *pattern matching*. It's recommended to use *error handling* to process errors effectively. These two topics will be covered in a later chapter.

