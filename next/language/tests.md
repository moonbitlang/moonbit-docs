# Writing Tests

## Test Blocks

MoonBit provides the test code block for writing test cases. For example:

```{literalinclude} /sources/language/src/test/top.mbt
:language: moonbit
:start-after: start test 1
:end-before: end test 1
```

A test code block is essentially a function that returns a `Unit` but may throws a `String` on error, or `Unit!String` as one would see in its signature at the position of return type. It is called during the execution of `moon test` and outputs a test report through the build system. The `assert_eq` function is from the standard library; if the assertion fails, it prints an error message and terminates the test. The string `"test_name"` is used to identify the test case and is optional. If it starts with `"panic"`, it indicates that the expected behavior of the test is to trigger a panic, and the test will only pass if the panic is triggered. For example:

```{literalinclude} /sources/language/src/test/top.mbt
:language: moonbit
:start-after: start test 2
:end-before: end test 2
```