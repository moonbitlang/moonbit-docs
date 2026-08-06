# Unsafe Cycle-Free Attribute

The `#unsafe_cycle_free` attribute is an advanced optimization assertion for a
struct, enum, or newtype declaration. It tells the compiler that no value of
the annotated type will ever participate in a reference cycle. The compiler
trusts this assertion during cycle-capability analysis and does not verify it.

```moonbit
#unsafe_cycle_free
pub(all) struct CycleFreeNode {
  mut next : CycleFreeNode?
}
```
