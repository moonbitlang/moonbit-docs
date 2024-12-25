# Test

MoonBit has built-in testing support. There is no need to import or configure extra packages or tools; just use the test block and write the test code inside.

**Note: this feature is not supported in this tour. You can try it in our [playground](https://try.moonbitlang.com) or in your terminal if the MoonBit toolchain is installed.**

In the first test block, we test some properties using the built-in functions `assert_eq`, `assert_false`, and `assert_true`.
By running `moon test` in the terminal or clicking the test button in your integrated development environment (IDE), the tests will be executed.

## Maintaining Tests

Sometimes it's tedious to maintain the expected value manually. MoonBit also supports built-in *snapshot tests*. Snapshot tests will run the tested code and store the expected result as a snapshot.

In the second test block, we use the `inspect` function to test the result of `fib` and the array's `map` method.
By running `moon test --update` in the terminal or clicking the `Update test` button in your IDE, the result will be automatically inserted as the second argument.

The next time you run the test, it will report any differences between the current result and the stored result. You can update the stored result to the new result by using the `--update` flag.


