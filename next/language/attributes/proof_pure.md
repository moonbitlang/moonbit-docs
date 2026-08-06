# Proof Pure Attribute

The `#proof_pure` attribute makes a side-effect-free function available to both
executable code and proof-oriented logic.

```{literalinclude} /sources/verification/src/top.mbt
:language: moonbit
:start-after: start proof pure 1
:end-before: end proof pure 1
```

It currently supports regular top-level functions and ordinary methods.
Verification contracts, direct recursion, and mutual recursion are not yet
supported on `#proof_pure` definitions.

For its role in specifications and a complete example, see
[Formal Verification](/language/verification.md#proof-specific-annotations).
