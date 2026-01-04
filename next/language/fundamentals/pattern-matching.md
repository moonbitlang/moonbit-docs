# Pattern Matching

Pattern matching allows us to match on specific pattern and bind data from data structures.

## Simple Patterns

We can pattern match expressions against

- literals, such as boolean values, numbers, chars, strings, etc
- constants
- structs
- enums
- arrays
- maps
- JSONs

and so on. We can define identifiers to bind the matched values so that they can be used later.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start simple pattern 1
:end-before: end simple pattern 1
```

We can use `_` as wildcards for the values we don't care about, and use `..` to ignore remaining fields of struct or enum, or array (see [array pattern](#array-pattern)).

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start simple pattern 2
:end-before: end simple pattern 2
```

We can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 3
:end-before: end pattern 3
```

## Array Pattern

Array patterns can be used to match on the following types to obtain their
corresponding elements or views:

| Type                                   | Element | View           |
|----------------------------------------|---------|----------------|
| Array[T], ArrayView[T], FixedArray[T]   | T       | ArrayView[T]   |
| Bytes, BytesView                       | Byte    | BytesView      |
| String, StringView                     | Char    | StringView     |


Array patterns have the following forms:

- `[]` : matching for empty array
- `[pa, pb, pc]` : matching for array of length three, and bind `pa`, `pb`, `pc`
  to the three elements
- `[pa, ..rest, pb]` : matching for array with at least two elements, and bind
  `pa` to the first element, `pb` to the last element, and `rest` to the
  remaining elements. the binder `rest` can be omitted if the rest of the
  elements are not needed. Arbitrary number of elements are allowed preceding
  and following the `..` part. Because `..` can match uncertain number of
  elements, it can appear at most once in an array pattern.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:start-after: start pattern 2
:end-before: end pattern 2
```

Array patterns provide a unicode-safe way to manipulate strings, meaning that it
respects the code unit boundaries. For example, we can check if a string is a
 palindrome:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:start-after: start array pattern 1
:end-before: end array pattern 1
```

When there are consecutive char or byte constants in an array pattern, the
pattern spread `..` operator can be used to combine them to make the code look
cleaner. Note that in this case the `..` followed by string or bytes constant
matches exact number of elements so its usage is not limited to once.

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:start-after: start array pattern 2
:end-before: end array pattern 2
```

## Range Pattern
For builtin integer types and `Char`, MoonBit allows matching whether the value falls in a specific range.

Range patterns have the form `a..<b` or `a..=b`, where `..<` means the upper bound is exclusive, and `..=` means inclusive upper bound.
`a` and `b` can be one of:

- literal
- named constant declared with `const`
- `_`, meaning the pattern has no restriction on this side

Here are some examples:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 4
:end-before: end pattern 4
```

## Map Pattern

MoonBit allows convenient matching on map-like data structures.
Inside a map pattern, the `key : value` syntax will match if `key` exists in the map, and match the value of `key` with pattern `value`.
The `key? : value` syntax will match no matter `key` exists or not, and `value` will be matched against `map[key]` (an optional).

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 5
:end-before: end pattern 5
```

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V` (see [method and trait](./methods.md)).
- Currently, the key part of map pattern must be a literal or constant
- Map patterns are always open: the unmatched keys are silently ignored, and `..` needs to be added to identify this nature
- Map pattern will be compiled to efficient code: every key will be fetched at most once

## Json Pattern

When the matched value has type `Json`, literal patterns can be used directly, together with constructors:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start pattern 6
:end-before: end pattern 6
```

## Guard condition

Each case in a pattern matching expression can have a guard condition. A guard
condition is a boolean expression that must be true for the case to be matched.
If the guard condition is false, the case is skipped and the next case is tried.
For example:
```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start guard condition 1
:end-before: end guard condition 1
```

Note that the guard conditions will not be considered when checking if all
patterns are covered by the match expression. So you will see a warning of
partial match for the following case:

```{literalinclude} /sources/language/src/pattern/top.mbt
:language: moonbit
:dedent:
:start-after: start guard condition 2
:end-before: end guard condition 2
```

``````{warning}
It is not encouraged to call a function that mutates a part of the value being
matched inside a guard condition. When such case happens, the part being mutated
will not be re-evaluated in the subsequent patterns. Use it with caution.
``````
