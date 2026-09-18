# Non-exhaustive Enum Attribute

The `#non_exhaustive` attribute marks an `enum` whose defining package may add
constructors in a future release. It is valid only on enum declarations.

```{literalinclude} /sources/language/src/nonexhaustive/base/top.mbt
:language: moonbit
:start-after: start non exhaustive declaration
:end-before: end non exhaustive declaration
```

Code outside the defining package must handle potential future constructors
with a `Type::..` pattern:

```{literalinclude} /sources/language/src/nonexhaustive/app/top.mbt
:language: moonbit
:start-after: start non exhaustive match
:end-before: end non exhaustive match
```

The `Type::..` pattern is specifically for forward compatibility. It does not
replace the enum's currently known constructors: match those constructors
explicitly before this pattern. A wildcard pattern (`_`) is not a substitute
for `Type::..` when handling constructors added by a future version of the
defining package.

Adding a constructor to a `#non_exhaustive` enum is therefore compatible with
downstream matches that use `Type::..`.
