# Documentation

## Doc Comments

Doc comments are comments prefix with `///` in each line in the leading of toplevel structure like `fn`, `let`, `enum`, `struct` or `type`. The doc comments are written in markdown.

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc string 1
:end-before: end doc string 1

```

Markdown code blocks inside docstrings marked with `mbt check` are treated as
document tests. `moon check` and `moon test` will automatically check and run
these tests, so that examples in docstring are always up-to-date.
Wrap the snippet in `test { .. }` when you want a test block:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc test 1
:end-before: end doc test 1
```

Doc tests also apply to literate `.mbt.md` files. For a standalone file, run
`moon check README.mbt.md` and `moon test README.mbt.md`. Inside a project, use
the package-level `moon check` and `moon test` instead.

If you want to prevent a code snippet from being treated as a document test,
mark it with a language id other than `mbt check` on the markdown code block:

```{literalinclude} /sources/language/src/misc/top.mbt
:language: moonbit
:start-after: start doc test 2
:end-before: end doc test 2
```

Currently, document tests are always [blackbox tests](/language/tests.md#blackbox-tests-and-whitebox-tests).
So private definitions cannot have document test.
