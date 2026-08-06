# Proof Import Attribute

The `#proof_import(module)` attribute maps a proof-only logic declaration in a
`.mbtp` file to a symbol from a Why3 module. The declaration's string body names
the Why3 symbol; it is not an executable MoonBit expression.

```{literalinclude} /sources/verification/src/proof_shim.mbtp
:language: moonbit
:start-after: start proof import 1
:end-before: end proof import 1
```

Here, `set.Fset` is the Why3 module path, while `"mem"`, `"empty"`, and `"add"`
name symbols in that module. These declarations affect verification lowering
only and do not provide runtime implementations or FFI bindings. The final
lemma creates a proof obligation; the imported declarations themselves do not.

The declared signatures and symbol mappings are part of the trusted
verification boundary. For a complete example and usage guidance, see
[Formal Verification](/language/verification.md#proof-specific-annotations).
