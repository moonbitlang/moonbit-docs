# Myers diff 2

This is the second post in the diff series. In the [previous one](/example/myers-diff/myers-diff.md), we learned how to transform the process of computing diffs into a graph search problem and how to search for the shortest edit distance. In this article, we will learn how to extend the search process from the previous post to obtain the complete edit sequence.

## Recording the Search Process

The first step to obtaining the complete edit sequence is to save the entire editing process. This step is relatively simple; we just need to save the current search depth `d` and the graph node with depth `d` at the beginning of each search round.

```{literalinclude} /sources/diff/src/part2/diff.mbt
:language: moonbit
:start-after: start shortest_edit definition
:end-before: end shortest_edit definition
```

## Backtracking the Edit Path

After recording the entire search process, the next step is to walk back from the endpoint to find the path taken. But before we do that, let's first define the `Edit` type.

```{literalinclude} /sources/diff/src/part2/edit.mbt
:language: moonbit
:start-after: start edit definition
:end-before: end edit definition
```

Next, let's perform the backtracking.

```{literalinclude} /sources/diff/src/part2/diff.mbt
:language: moonbit
:start-after: start backtrack_fst definition
:end-before: end backtrack_fst definition
```

The method of backtracking is essentially the same as forward search, just in reverse.

- Calculate the current `k` value using `x` and `y`.

- Access the historical records and use the same judgment criteria as in forward search to find the `k` value at the previous search round.

- Restore the coordinates of the previous search round.

- Try free movement and record the corresponding edit actions.

- Determine the type of edit that caused the change in `k` value.

- Continue iterating.

```{literalinclude} /sources/diff/src/part2/diff.mbt
:language: moonbit
:dedent:
:start-after: start backtrack_snd definition
:end-before: end backtrack_snd definition
```

Combining the two functions, we get a complete `diff` implementation.

```{literalinclude} /sources/diff/src/part2/diff.mbt
:language: moonbit
:start-after: start diff definition
:end-before: end diff definition
```

## Printing the Diff

To print a neat diff, we need to left-align the text. Also, due to the order issue during backtracking, we need to print from back to front.

```{literalinclude} /sources/diff/src/part2/edit.mbt
:language: moonbit
:start-after: start pprint definition
:end-before: end pprint definition
```

The result is as follows:

```diff
-    1         A
-    2         B
     3    1    C
+         2    B
     4    3    A
     5    4    B
-    6         B
     7    5    A
+         6    C
```

## Conclusion

The Myers algorithm demonstrated above is complete, but due to the frequent copying of arrays, it has a very large space overhead. Therefore, most software like Git uses a linear variant of the diff algorithm (found in the appendix of the original paper). This variant may sometimes produce diffs of lower quality (harder for humans to read) than the standard Myers algorithm but can still ensure the shortest edit sequence.
