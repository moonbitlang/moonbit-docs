# Formal Verification

MoonBit has experimental support for formal verification through `moon prove`.
It lets you write executable MoonBit code, state logical properties about that
code, and discharge the generated proof obligations with the SMT solvers.

At a high level, the workflow looks like this:

1. Write executable code in `.mbt` files.
2. Write predicates, logical helper functions, and lemmas in `.mbtp` files.
3. Enable proof mode in the package.
4. Run `moon prove`.

## Overview Example: Binary Search

The following package gives a compact overview of how verification in MoonBit
fits together. It shows:

- package-level proof enablement
- logic-side predicates in `.mbtp`
- a program-side function in `.mbt`
- preconditions and postconditions
- loop invariants and `proof_yield`
- local `proof_assert` steps
- `proof_reasoning` as a proof-oriented explanation of the loop

First, enable proofs for the package:

```{literalinclude} /sources/verification/snippets/moon.pkg
:language: moonbit
```

Then define the logic-side specification in `.mbtp`:

```{literalinclude} /sources/verification/src/top.mbtp
:language: moonbit
:start-after: start predicate 1
:end-before: end predicate 1
```

Finally, implement the executable function in `.mbt`:

```{literalinclude} /sources/verification/src/top.mbt
:language: moonbit
:start-after: start contract 1
:end-before: end contract 1
```

This example already shows the main structure of verified MoonBit code:

- `sorted` and `binary_search_ok` are logic-side predicates
- `binary_search` is executable program-side code
- the `where { ... }` block attaches logic-side contracts to the function
- `proof_assert` records local facts that help the prover
- the loop invariants describe the shrinking search window
- `proof_reasoning` records the proof idea in structured prose

The rest of this page explains these pieces in more detail and introduces
additional features such as `#proof_pure`, `proof_decrease`,
`proof_axiomatized`, model-based verification, and the trusted surface.

## Setup

### Environment Setup

`moon prove` relies on the external Why3 verification toolchain. MoonBit lowers
proof-enabled packages to Why3, and Why3 then dispatches proof obligations to
one or more external solvers.

### Why3

Why3 is required to run formal verification in MoonBit.

- It is recommended to install Why3 through `opam`.
- The recommended pinned version is `1.7.2`.

Using `opam` makes it easier to keep Why3 aligned with the version expected by
the current MoonBit proof pipeline.

### External Solvers

At least one external solver must also be installed.

MoonBit currently supports:

- `z3`
- `cvc5`
- `alt-ergo`

Installing more than one solver can improve prover coverage, but a working setup
only requires one of them to be available.

### Enabling Proofs in a Package

Proof support is enabled per package in `moon.pkg`, as shown in the overview
example above.

Once enabled, the package can contain both ordinary MoonBit source files and
proof-oriented `.mbtp` files. Proof enablement is package-local: if multiple
packages in a module carry proofs, each of those packages must enable it.

## Structure of Verified Code

### Source Layout

Verification-oriented packages usually split into two layers:

- `.mbt`: executable code, contracts, loop invariants, and local proof steps
- `.mbtp`: predicates, abstract models, invariants, and lemmas

That split keeps runtime code readable while making proof structure explicit.
In the [binary search overview](#overview-example-binary-search), the predicates live in `.mbtp` and the
executable search function lives in `.mbt`.

### Program Side and Logic Side

MoonBit verification has a clear distinction between the program side and the
logic side.

- The program side is executable MoonBit code.
- The logic side is used for specifications and proofs, and may not correspond
  to runtime code at all.

Definitions in `.mbt` files are on the program side. Definitions in `.mbtp`
files are on the logic side.

This distinction is important because program-side definitions and logic-side
definitions are separated:

- program-side definitions are executable and can be called by ordinary MoonBit
  code
- logic-side definitions are used by specifications and proofs
- logic-side definitions in `.mbtp` are not ordinary runtime functions
- program-side code does not call logic-side definitions as part of execution
- logic-side specifications do not in general call arbitrary program-side
  definitions

This separation is the reason verified packages often have both:

- program-side helper functions used by execution
- logic-side predicates or model functions used by contracts

When one definition needs to be visible from both sides, `#proof_pure` is the
mechanism for doing that.

Within a `.mbt` file, contracts and proof annotations are the places where
logic-side reasoning appears inside program code. In particular:

- `proof_require` and `proof_ensure` are logic-side specifications attached to
  program functions
- `proof_assert` states a logical fact that must be proved at that point
- loop annotations such as `proof_invariant`, `proof_yield`, and
  `proof_reasoning` are logic-side statements about executable loops

## Writing Specifications and Proofs

### Contracts in `.mbt`

MoonBit uses `where { ... }` clauses for function contracts. In the binary
search overview, the function contract appears directly on the program-side
definition:

- `proof_require` states a precondition.
- `proof_ensure` states a postcondition.
- `result` refers to the function result.

Inside executable code, `proof_assert` can be used to record intermediate facts
that help the prover connect the implementation to the specification.

This is often the point where program-side implementation facts are connected to
logic-side predicates and postconditions.

### Proof-Specific Annotations

Besides `proof_require`, `proof_ensure`, and `proof_assert`, MoonBit also has
proof-specific annotations that control how definitions are treated by the proof
pipeline.

### `#proof_pure`

`#proof_pure` marks a function as pure from the verifier's point of view. This
is useful for helper functions that compute logical quantities used in
predicates and postconditions, while still being visible on the program side.

```{literalinclude} /sources/verification/src/top.mbt
:language: moonbit
:start-after: start proof pure 1
:end-before: end proof pure 1
```

The same helper can then be used in a specification:

```{literalinclude} /sources/verification/src/top.mbtp
:language: moonbit
:start-after: start proof pure use 1
:end-before: end proof pure use 1
```

The rationale for `#proof_pure` is that some computations naturally belong on
both sides. A helper such as `height` on a tree can be useful in executable
code, but specifications may also want to talk about the same quantity.

Without `#proof_pure`, this typically means:

- writing one program-side definition for execution
- writing a second logic-side definition for specifications
- proving that the two definitions are equivalent before using them

`#proof_pure` avoids that duplication by allowing one side-effect-free MoonBit
definition to be shared across program code and proof-oriented logic.

In larger verified packages, `#proof_pure` is commonly used for helpers such as
structural measures like height, ranking functions, summaries, and other
proof-facing computations that should behave like mathematical functions.

At the moment, `#proof_pure` helpers are best treated as pure specification
helpers rather than fully contracted verified functions. In particular, support
for attaching ordinary verification contracts directly to `#proof_pure`
definitions is still limited.

### `proof_decrease`

`proof_decrease` supplies a termination measure for recursive definitions.

```{literalinclude} /sources/verification/src/top.mbt
:language: moonbit
:start-after: start proof decrease 1
:end-before: end proof decrease 1
```

This annotation is especially important when structural recursion or a numeric
measure is not obvious to the prover from the function body alone.

### `proof_axiomatized`

`proof_axiomatized` marks a contracted function or lemma as assumed rather than
proved.

This is useful when a definition should be available to later proofs, but its
implementation or proof is intentionally left outside the current verification
boundary.

In practice, `proof_axiomatized` should be used sparingly:

- on a function, it means the verifier assumes the stated contract
- on a lemma, it means the verifier assumes the stated conclusion

For example:

```{literalinclude} /sources/verification/src/top.mbt
:language: moonbit
:start-after: start proof axiomatized 1
:end-before: end proof axiomatized 1
```

This kind of declaration can be useful as a temporary bridge while a proof is
still being developed, or when the trusted boundary is intentional and explicit.
The important point is that `moon prove` will use the contract as an
assumption, rather than proving it from the function body.

Because these assumptions are not discharged by `moon prove`, they become part
of the trusted surface of the verified package.

### Predicates and Lemmas in `.mbtp`

Logical properties live in `.mbtp` files. In the [binary search overview](#overview-example-binary-search), the
logic side defines:

- `in_bounds` as a basic indexing predicate
- `sorted` as the precondition on the input array
- `binary_search_ok` as the postcondition relating the result to the array and
  the key

For example, predicates in `.mbtp` can define the logical vocabulary used by
contracts:

```{literalinclude} /sources/verification/src/top.mbtp
:language: moonbit
:start-after: start predicate 1
:end-before: end predicate 1
```

For larger verified packages, `.mbtp` also holds:

- abstract model functions such as `model(x)`
- representation invariants such as `bridge_inv(x)` or `sparse_array_inv(x)`
- named postconditions such as `deposit_post(...)`
- reusable lemmas

Lemmas are proof-only declarations that capture reusable facts. Small lemmas may
have an empty body when the prover can discharge them directly, while larger
lemmas can use recursive proof structure:

```{literalinclude} /sources/verification/snippets/recursive_lemma.mbtp
:language: moonbit
:start-after: start lemma 1
:end-before: end lemma 1
```

In this example, `avl_inv` is a representation invariant for an AVL tree, and
the lemma proves `height(t)` is nonnegative by structural recursion on `t`.

Lemma bodies vary with the amount of proof guidance the solver needs:

- some lemmas have an empty body because the verifier can discharge them directly
- some lemmas use a sequence of `proof_assert` steps to expose intermediate facts
- recursive lemmas can also call other lemmas, including themselves on smaller inputs

### Loop Invariants

Loops are verified with proof-specific clauses in the loop's `where { ... }`
block. In the [binary search overview](#overview-example-binary-search), the loop invariants state that:

- the current search window is always a valid slice `[i, j)`
- every index before `i` contains a value `< key`
- every index from `j` onward contains a value `> key`

The most common loop proof annotations are:

- `proof_invariant`: facts that must hold at every iteration boundary
- `proof_yield`: facts that must hold for values yielded by `break`
- `proof_reasoning`: a proof-oriented explanation of why the loop is correct

In practice, good loop invariants describe the current search window, prefix, or
processed region rather than the entire algorithm all at once.

### Model-Based Verification

For data structures and stateful systems, the most useful pattern is often:

1. define an abstract model,
2. define a representation invariant,
3. specify each operation against the abstract model.

An AVL tree is a representative example of this style:

```{literalinclude} /sources/verification/snippets/avl_model.mbtp
:language: moonbit
:start-after: start model 1
:end-before: end model 1
```

Here:

- `model()` maps a concrete tree to its abstract finite-set view
- the quantified conditions inline the ordering constraints over that abstract
  model
- `avl_inv` ties together recursive well-formedness, search-tree ordering, and
  cached-height correctness

This style scales much better than writing large inline boolean formulas in each
contract. Each operation can be specified in terms of the abstract model and
the invariant, and the implementation can then prove local facts until the
named postcondition follows.

### Recommended Style

- Keep executable logic in `.mbt` and proof logic in `.mbtp`.
- Treat the program side and the logic side as distinct layers with a narrow
  bridge between them.
- Prefer named predicates over large inline formulas.
- Use small, stable invariants and postconditions such as `*_inv` and `*_post`.
- Add `proof_assert` after important construction steps, branches, and loop
  updates when the prover needs help.
- Start with simple algorithmic proofs, then move to model-based verification
  for data structures and protocols.
- Be deliberate about recursive helpers: `#proof_pure` and `proof_decrease`
  often determine whether a proof remains maintainable.

## Running Verification

### What `moon prove` Checks

Running `moon prove` asks the verifier to prove obligations such as:

- function preconditions imply the function body is safe to execute
- postconditions hold on every return path
- `proof_assert` statements are valid
- loop invariants hold initially and are preserved
- loop termination measures decrease when the loop form supports them
- bounds checks and similar safety properties required by the proof

### Running the Verifier

From a module root, run:

```bash
moon prove
```

This tries to prove the proof-enabled packages in the current module.

To prove a single package, pass its path:

```bash
moon prove path/to/package
```

In this targeted mode, MoonBit tries to prove only the selected package. Its
dependencies are assumed rather than reproved as part of the same command.

MoonBit lowers the proof-enabled package to Why3 and invokes the configured
provers on the generated verification conditions.

`moon check` and `moon prove` serve different purposes here. `moon check`
validates the package as MoonBit code, while `moon prove` tries to discharge
its proof obligations.

## Trust Model and Limitations

### Trusted Assumptions

Like any verification system, MoonBit's proof story has a trusted surface: some
facts are assumed by the frontend and backend rather than proved inside user
code.

This trusted surface also includes any user-written item marked
`proof_axiomatized`.

The main trusted assumptions today are:

- verification reasons about mathematical integers rather than machine integers
- any item marked `proof_axiomatized` is assumed rather than proved

For integers, this means proof obligations are checked in an unbounded integer
model. As a result:

- arithmetic proofs do not currently model runtime overflow
- a program can be correct in the proof model and still need explicit range
  discipline in execution
- machine-integer verification is planned, but is not the current default

### Current Status

Formal verification in MoonBit is still experimental. The surface syntax,
prover integration, and proof ergonomics are actively evolving, so it is best
to treat this as an advanced feature for packages that benefit from strong,
machine-checked guarantees.

### Preferred Verification Style

MoonBit's current verifier works best with a functional proof style and
model-based specifications.

Imperative features such as local mutation and in-place `FixedArray` updates are
supported, but their verified use is more limited:

- mutable state is expected to remain local
- escaping uses of `FixedArray` are currently not supported
- when both formulations are available, functional-style programs are preferred

## Further Reading

For additional verified programs and reusable proof-oriented libraries, see the
[`moonbit-community/verified`](https://github.com/moonbit-community/verified)
repository.
