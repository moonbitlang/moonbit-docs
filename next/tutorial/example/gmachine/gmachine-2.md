# G-Machine 2

This article is the second in the series on implementing lazy evaluation in MoonBit. In the first part, we explored the purposes of lazy evaluation and a typical abstract machine for lazy evaluation, the G-Machine, and implemented some basic G-Machine instructions. In this article, we will further extend the G-Machine implementation from the previous article to support `let` expressions and basic arithmetic, comparison, and other operations.

## let Expressions

The `let` expression in coref differs slightly from that in MoonBit. A `let` expression can create multiple variables but can only be used within a limited scope. Here is an example:

```moonbit
{
  let x = n + m
  let y = x + 42
  x * y
}
```

Equivalent coref expression:

```clojure
(let ([x (add n m)]
      [y (add x 42)])
  (mul x y)) ;; xy can only be used within let
```

It is important to note that coref's `let` expressions must follow a sequential order. For example, the following is not valid:

```clojure
(let ([y (add x 42)]
      [x (add n m)])
  (mul x y))
```

In contrast, `letrec` is more complex as it allows the local variables defined to reference each other without considering the order of their definitions.

Before implementing `let` (and the more complex `letrec`), we first need to modify the current parameter passing method. The local variables created by `let` should intuitively be accessed in the same way as parameters, but the local variables defined by `let` do not correspond to `NApp` nodes. Therefore, we need to adjust the stack parameters before calling the supercombinator.

The adjustment is done in the implementation of the `Unwind` instruction. If the supercombinator has no parameters, it is the same as the original unwind. When there are parameters, the top address of the supercombinator node is discarded, and the `rearrange` function is called.

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start rearrange definition
:end-before: end rearrange definition
```

The `rearrange` function assumes that the first N addresses on the stack point to a series of `NApp` nodes. It keeps the bottommost one (used as Redex update), cleans up the top N-1 addresses, and then places N addresses that directly point to the parameters.

After this, both parameters and local variables can be accessed using the same command by changing the `PushArg` instruction to a more general `Push` instruction.

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start push definition
:end-before: end push definition
```

The next issue is that we need something to clean up. Consider the following expression:

```clojure
(let ([x1 e1]
      [x2 e2])
  expr)
```

After constructing the graph corresponding to the expression `expr`, the stack still contains addresses pointing to e1 and e2 (corresponding to variables x1 and x2), as shown below (the stack grows from bottom to top):

```
<Address pointing to expr>
       |
<Address pointing to x2>
       |
<Address pointing to x1>
       |
...remaining stack...
```

Therefore, we need a new instruction to clean up these no longer needed addresses. It is called `Slide`. As the name suggests, the function of `Slide(n)` is to skip the first address and delete the following N addresses.

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start slide definition
:end-before: end slide definition
```

Now we can compile `let`. We will compile the expressions corresponding to local variables using the `compileC` function. Then, traverse the list of variable definitions (`defs`), compile and update the corresponding offsets in order. Finally, use the passed `comp` function to compile the main expression and add the `Slide` instruction to clean up the unused addresses.

> Compiling the main expression using the passed function makes it easy to reuse when adding subsequent features.

```{literalinclude} /sources/gmachine/src/part2/compile.mbt
:language: moonbit
:start-after: start compile_let definition
:end-before: end compile_let definition
```

The semantics of `letrec` are more complex - it allows the N variables within the expression to reference each other, so we need to pre-allocate N addresses and place them on the stack. We need a new instruction: `Alloc(N)`, which pre-allocates N `NInd` nodes and pushes the addresses onto the stack sequentially. The addresses in these indirect nodes are negative and only serve as placeholders.

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start alloc definition
:end-before: end alloc definition
```

The steps to compile letrec are similar to `let`:

- Use `Alloc(n)` to allocate N addresses.
- Use the `loop` expression to build a complete environment.
- Compile the local variables in `defs`, using the `Update` instruction to update the results to the pre-allocated addresses after compiling each one.
- Compile the main expression and use the `Slide` instruction to clean up.

```{literalinclude} /sources/gmachine/src/part2/compile.mbt
:language: moonbit
:start-after: start compile_letrec definition
:end-before: end compile_letrec definition
```

## Adding Primitives

From this step, we can finally perform basic integer operations such as arithmetic, comparison, and checking if two numbers are equal. First, modify the `Instruction` type to add related instructions.

```rust
  Add
  Sub
  Mul
  Div
  Neg
  Eq // ==
  Ne // !=
  Lt // <
  Le // <=
  Gt // >
  Ge // >=
  Cond(List[Instruction], List[Instruction])
```

At first glance, implementing these instructions seems simple. Take `Add` as an example: just pop two top addresses from the stack, retrieve the corresponding numbers from memory, perform the operation, and push the result address back onto the stack.

```rust
fn add(self : GState) -> Unit {
  let (a1, a2) = self.pop2() // Pop two top addresses
  match (self.heap[a1], self.heap[a2]) {
    (NNum(n1), NNum(n2)) => {
      let newnode = Node::NNum(n1 + n2)
      let addr = self.heap.alloc(newnode)
      self.putStack(addr)
    }
    ......
  }
}
```

However, the next problem we face is that this is a lazy evaluation language. The parameters of `add` are likely not yet computed (i.e., not `NNum` nodes). We also need an instruction that can force a computation to give a result or never stop computing. We call it `Eval` (short for Evaluation).

> In jargon, the result of such a computation is called Weak Head Normal Form (WHNF).

At the same time, we need to modify the structure of `GState` and add a state called `dump`. Its type is `List[(List[Instruction], List[Addr])]`, used by `Eval` and `Unwind` instructions.

The implementation of the `Eval` instruction is not complicated:

- Pop the top address of the stack.

- Save the current unexecuted instruction sequence and stack (by putting them into the dump).

- Clear the current stack and place the previously saved address.

- Clear the current instruction sequence and place the `Unwind` instruction.

> This is similar to how strict evaluation languages handle saving caller contexts, but practical implementations would use more efficient methods.

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start eval definition
:end-before: end eval definition
```

This simple definition requires modifying the `Unwind` instruction to restore the context when `Unwind` in the `NNum` branch finds that there is a recoverable context (`dump` is not empty).

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start unwind definition
:end-before: end unwind definition
```

Next, we need to implement arithmetic and comparison instructions. We use two functions to simplify the form of binary operations. The result of the comparison instruction is a boolean value, and for simplicity, we use numbers to represent it: 0 for `false`, 1 for `true`.

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start op definition
:end-before: end op definition
```

Finally, implement branching:

```{literalinclude} /sources/gmachine/src/part2/vm.mbt
:language: moonbit
:start-after: start cond definition
:end-before: end cond definition
```

No major adjustments are needed in the compilation part, just add some predefined programs:

```{literalinclude} /sources/gmachine/src/part2/compile.mbt
:language: moonbit
:start-after: start prim definition
:end-before: end prim definition
```

and modify the initial instruction sequence

```{literalinclude} /sources/gmachine/src/part2/top.mbt
:language: moonbit
:dedent:
:start-after: start init definition
:end-before: end init definition
```

## Conclusion

In the next part, we will improve the code generation for primitives and add support for data structures.
