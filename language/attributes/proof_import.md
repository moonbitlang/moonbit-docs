# Proof Import Attribute

The `#proof_import(module)` attribute maps a proof-only logic declaration in a
`.mbtp` file to a symbol from a Why3 module. The declaration's string body names
the Why3 symbol; it is not an executable MoonBit expression.

```moonbit
#proof_import("set.Fset")
fn proof_set_mem(x : Int, set : ProofSet[Int]) -> Bool = "mem"

#proof_import("set.Fset")
fn proof_set_empty() -> ProofSet[Int] = "empty"

#proof_import("set.Fset")
fn proof_set_add(x : Int, set : ProofSet[Int]) -> ProofSet[Int] = "add"

lemma proof_set_add_contains(x : Int) where {
  proof_ensure: proof_set_mem(
    x,
    proof_set_add(x, proof_set_empty()),
  ),
} {}
```

Here, `set.Fset` is the Why3 module path, while `"mem"`, `"empty"`, and `"add"`
name symbols in that module. These declarations affect verification lowering
only and do not provide runtime implementations or FFI bindings. The final
lemma creates a proof obligation; the imported declarations themselves do not.

The declared signatures and symbol mappings are part of the trusted
verification boundary. For a complete example and usage guidance, see
[Formal Verification](https://docs.moonbitlang.com/en/latest/language/verification.html#proof-specific-annotations).
