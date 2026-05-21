# Module attribute

The `module` attribute is used to declare the module dependency for JavaScript backend.

In `cjs` format, it is interpreted as `require`, and in `esm` format, it is interpreted as `import`.

<!-- MANUAL CHECK -->

```{literalinclude} /sources/language/src/attributes/top.mbt
:language: moonbit
:start-after: start module
:end-before: end module
```
