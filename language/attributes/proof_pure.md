# Proof Pure Attribute

The `#proof_pure` attribute makes a side-effect-free function available to both
executable code and proof-oriented logic.

```moonbit
#proof_pure
fn height(t : Tree) -> Int {
  match t {
    Empty => 0
    Node(_, _, _, h) => h
  }
}
```

It currently supports regular top-level functions and ordinary methods.
Verification contracts, direct recursion, and mutual recursion are not yet
supported on `#proof_pure` definitions.

For its role in specifications and a complete example, see
[Formal Verification](../verification.md#proof-specific-annotations).
