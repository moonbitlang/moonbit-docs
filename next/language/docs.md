# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`,`let`,`enum`,`struct`,`type`. The doc comments contains a markdown text and several pragmas.

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc string 1
:end-before: end doc string 1
```

### Pragmas

Pragmas are annotations inside doc comments. They all take the form `/// @word ...`. The _word_ indicates the type of pragma and is followed optionally by several _word_ or string literals. Pragmas do not normally affect the meaning of programs. Unrecognized pragmas will be reported as warnings.

- Alert Pragmas

  Alert pragmas in doc comments of functions will be reported when those functions are referenced. This mechanism is a generalized way to mark functions as `deprecated` or `unsafe`.

  It takes the form `@alert category "alert message..."`.

  The category can be an arbitrary identifier. It allows configuration to decide which alerts are enabled or turned into errors.

  <!-- MANUAL CHECK -->
  ```moonbit
  /// @alert deprecated "Use foo2 instead"
  pub fn foo() -> Unit {
    ...
  }

  /// @alert unsafe "Div will cause an error when y is zero"
  pub fn div(x : Int, y : Int) -> Int {
    ...
  }

  test {
    // Warning (Alert deprecated): Use foo2 instead
    foo()
    // Warning (Alert unsafe): Div will cause an error when y is zero
    div(1, 2) |> ignore
  }
  ```