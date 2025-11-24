# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`, `let`, `enum`, `struct` or `type`. The doc comments are written in markdown.

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc string 1
:end-before: end doc string 1

```

Markdown code block inside docstring will be considered document test,
`moon check` and `moon test` will automatically check and run these tests, so that examples in docstring are always up-to-date.
MoonBit will automatically wrap a test block around document test,
so there is no need to wrap `test { .. }` around document test:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc test 1
:end-before: end doc test 1
```

If you want to prevent a code snippet from being treated as document test,
mark it with a language id other than `mbt` on the markdown code block:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc test 2
:end-before: end doc test 2
```

Currently, document tests are always [blackbox tests](/language/tests.md#blackbox-tests-and-whitebox-tests).
So private definitions cannot have document test.
