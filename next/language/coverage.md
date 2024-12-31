# Measuring code coverage

We have included tooling for you to measure the code coverage of test and program runs.
The measurement is currently based on branch coverage.
In other words, it measures whether each program branch were executed,
and how many times if they were.

## Running code coverage in tests

To enable coverage instrumentation in tests,
you need to pass the `--enable-coverage` argument to `moon test`.

```
$ moon test --enable-coverage
...
Total tests: 3077, passed: 3077, failed: 0.
```

This will recompile the project
if they weren't previously compiled with coverage enabled.
The execution process will look the same,
but new coverage result files will be generated under the `target` directory.

```
$ ls target/wasm-gc/debug/test/ -w1
array
...
moonbit_coverage_1735628238436873.txt
moonbit_coverage_1735628238436883.txt
...
moonbit_coverage_1735628238514678.txt
option/
...
```

These files contain the information for the toolchain to determine
which parts of the program were executed,
and which parts weren't.

## Visualizing the coverage results

To visualize the result of coverage instrumentation,
you'll need to use the `moon coverage report` subcommand.

The subcommand can export the coverage in a number of formats,
controlled by the `-f` flag:

- Text summary: `summary`
- OCaml Bisect format: `bisect` (default)
- Coveralls JSON format: `coveralls`
- Cobertura XML format: `cobertura`
- HTML pages: `html`

### Text summary

`moon coverage report -f summary` exports the coverage data into stdout,
printing the covered points and total coverage point count for each file.

```
$ moon coverage report -f summary
array/array.mbt: 21/22
array/array_nonjs.mbt: 3/3
array/blit.mbt: 3/3
array/deprecated.mbt: 0/0
array/fixedarray.mbt: 115/115
array/fixedarray_sort.mbt: 110/116
array/fixedarray_sort_by.mbt: 58/61
array/slice.mbt: 6/6
array/sort.mbt: 70/70
array/sort_by.mbt: 56/61
...
```

### OCaml Bisect format

This is the default format to export, if `-f` is not specified.

`moon coverage report -f bisect` exports the coverage data into
a file `bisect.coverage` which can be read by [OCaml Bisect][bisect] tool.

[bisect]: https://github.com/aantron/bisect_ppx

### Coveralls JSON format

`moon coverage report -f coveralls` exports the coverage data into Coverall's JSON format.
This format is line-based, and can be read by both Coveralls and CodeCov.
You can find its specification [here](https://docs.coveralls.io/api-introduction#json-format-web-data).

```
$ moon coverage report -f coveralls
$ cat coveralls.json
{
    "source_files": [
        {
            "name": "builtin/console.mbt",
            "source_digest": "1c24532e12ac5bdf34b7618c9f38bd82",
            "coverage": [null,null,...,null,null]
        },
        {
            "name": "immut/array/array.mbt",
            "source_digest": "bcf1fb1d2f143ebf4423565d5a57e84f",
            "coverage": [null,null,null,...
```

You can directly send this coverage report to Coveralls or CodeCov using the `--send-to` argument.
The following is an example of using it in GitHub aCTIONS:

```
moon coverage report \
    -f coveralls \
    -o codecov_report.json \
    --service-name github \
    --service-job-id "$GITHUB_RUN_NUMBER" \
    --service-pull-request "${{ github.event.number }}" \
    --send-to coveralls

env:
    COVERALLS_REPO_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

More information can be found in `moon coverage report --help`.

### Cobertura XML format

`moon coverage report -f cobertura` exports the coverage data into a format that can be read by [Cobertura][].

[cobertura]: https://cobertura.github.io/cobertura/

### HTML

`moon coverage report -f html` export the coverage data into a series of human-readable HTML files.
The default export location is the folder named `_coverage`.

The `index.html` in the folder shows a list of all source files,
as well as the coverage percentage in them:

![Index of the HTML](../imgs/coverage_html_index.png)

Clicking on each file shows the coverage detail within each file.
Each coverage point (start of branch)
is represented by a highlighted character in the source code:
Red means the point is not covered among all runs,
and green means the point is covered in at least one run.

Each line is also highlighted by the coverage information,
with the same color coding.
Additionally,
yellow lines are those which has partial coverage:
some points in the line are covered, while others aren't.

Some lines will not have any highlight.
This does not mean the line has not been executed at all,
just the line is not a start of a branch.
Such a line shares the coverage of closest covered the line before it.

![Detailed coverage data](../imgs/coverage_html_page.png)

## Skipping coverage

Adding the pragma `/// @coverage.skip` skips all coverage operations within the function.
Additionally, all deprecated functions will not be covered.
