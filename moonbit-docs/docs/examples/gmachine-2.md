# G-Machine 2

This article is the second in the series on implementing lazy evaluation in MoonBit. In the first part, we explored the purposes of lazy evaluation and a typical abstract machine for lazy evaluation, the G-Machine, and implemented some basic G-Machine instructions. In this article, we will further extend the G-Machine implementation from the previous article to support `let` expressions and basic arithmetic, comparison, and other operations.

## let Expressions

The `let` expression in coref differs slightly from that in MoonBit. A `let` expression can create multiple variables but can only be used within a limited scope. Here is an example:

```rust
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

```rust
fn rearrange(self : GState, n : Int) -> Unit {
  let appnodes = take(self.stack, n)
  let args = map(fn (addr) {
  let NApp(_, arg) = self.heap[addr]
      arg
  }, appnodes)
  self.stack = append(args, drop(appnodes, n - 1))
}
```

The `rearrange` function assumes that the first N addresses on the stack point to a series of `NApp` nodes. It keeps the bottommost one (used as Redex update), cleans up the top N-1 addresses, and then places N addresses that directly point to the parameters.

After this, both parameters and local variables can be accessed using the same command by changing the `PushArg` instruction to a more general `Push` instruction.

```rust
fn push(self : GState, offset : Int) -> Unit {
  // Copy the address at offset + 1 to the top of the stack
  //    Push(n) a0 : . . . : an : s
  // => an : a0 : . . . : an : s
  let appaddr = nth(self.stack, offset)
  self.putStack(appaddr)
}
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

```rust
fn slide(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  self.stack = Cons(addr, drop(self.stack, n))
}
```

Now we can compile `let`. We will compile the expressions corresponding to local variables using the `compileC` function. Then, traverse the list of variable definitions (`defs`), compile and update the corresponding offsets in order. Finally, use the passed `comp` function to compile the main expression and add the `Slide` instruction to clean up the unused addresses.

> Compiling the main expression using the passed function makes it easy to reuse when adding subsequent features.

```rust
fn compileLet(comp : (RawExpr[String], List[(String, Int)]) -> List[Instruction], defs : List[(String, RawExpr[String])], expr : RawExpr[String], env : List[(String, Int)]) -> List[Instruction] {
  let (env, codes) = loop env, List::Nil, defs {
    env, acc, Nil => (env, acc)
    env, acc, Cons((name, expr), rest) => {
      let code = compileC(expr, env)
      // Update offsets and add offsets for local variables corresponding to name
      let env = List::Cons((name, 0), argOffset(1, env))
      continue env, append(acc, code), rest
    }
  }
  append(codes, append(comp(expr, env), List::[Slide(length(defs))]))
}
```

The semantics of `letrec` are more complex - it allows the N variables within the expression to reference each other, so we need to pre-allocate N addresses and place them on the stack. We need a new instruction: `Alloc(N)`, which pre-allocates N `NInd` nodes and pushes the addresses onto the stack sequentially. The addresses in these indirect nodes are negative and only serve as placeholders.

```rust
fn allocNodes(self : GState, n : Int) -> Unit {
  let dummynode : Node = NInd(Addr(-1))
  for i = 0; i < n; i = i + 1 {
    let addr = self.heap.alloc(dummynode)
    self.putStack(addr)
  }
}
```

The steps to compile letrec are similar to `let`:

- Use `Alloc(n)` to allocate N addresses.
- Use the `loop` expression to build a complete environment.
- Compile the local variables in `defs`, using the `Update` instruction to update the results to the pre-allocated addresses after compiling each one.
- Compile the main expression and use the `Slide` instruction to clean up.

```rust
fn compileLetrec(comp : (RawExpr[String], List[(String, Int)]) -> List[Instruction], defs : List[(String, RawExpr[String])], expr : RawExpr[String], env : List[(String, Int)]) -> List[Instruction] {
  let env = loop env, defs {
    env, Nil => env
    env, Cons((name, _), rest) => {
      let env = List::Cons((name, 0), argOffset(1, env))
      continue env, rest
    }
  }
  let n = length(defs)
  fn compileDefs(defs : List[(String, RawExpr[String])], offset : Int) -> List[Instruction] {
    match defs {
      Nil => append(comp(expr, env), List::[Slide(n)])
      Cons((_, expr), rest) => append(compileC(expr, env), Cons(Update(offset), compileDefs(rest, offset - 1)))
    }
  }
  Cons(Alloc(n), compileDefs(defs, n - 1))
}
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

```rust
fn eval(self : GState) -> Unit {
  let addr = self.pop1()
  self.putDump(self.code, self.stack)
  self.stack = List::[addr]
  self.code = List::[Unwind]
}
```

This simple definition requires modifying the `Unwind` instruction to restore the context when `Unwind` in the `NNum` branch finds that there is a recoverable context (`dump` is not empty).

```rust
fn unwind(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(_) => {
      match self.dump {
        Nil => self.putStack(addr)
        Cons((instrs, stack), restDump) => {
          // Restore the stack
          self.stack = stack
          self.putStack(addr)
          self.dump = restDump
          // Return to original code execution
          self.code = instrs
        }
      }
    }
    ......
  }
}
```

Next, we need to implement arithmetic and comparison instructions. We use two functions to simplify the form of binary operations. The result of the comparison instruction is a boolean value, and for simplicity, we use numbers to represent it: 0 for `false`, 1 for `true`.

```rust
fn liftArith2(self : GState, op : (Int, Int) -> Int) -> Unit {
  // Binary arithmetic operations
  let (a1, a2) = self.pop2()
  match (self.heap[a1], self.heap[a2]) {
    (NNum(n1), NNum(n2)) => {
      let newnode = Node::NNum(op(n1, n2))
      let addr = self.heap.alloc(newnode)
      self.putStack(addr)
    }
    (node1, node2) => abort("liftArith2: \(a1) = \(node1) \(a2) = \(node2)")
  }
}

fn liftCmp2(self : GState, op : (Int, Int) -> Bool) -> Unit {
  // Binary comparison operations
  let (a1, a2) = self.pop2()
  match (self.heap[a1], self.heap[a2]) {
    (NNum(n1), NNum(n2)) => {
      let flag = op(n1, n2)
      let newnode = if flag { Node::NNum(1) } else { Node::NNum(0) }
      let addr = self.heap.alloc(newnode)
      self.putStack(addr)
    }
    (node1, node2) => abort("liftCmp2: \(a1) = \(node1) \(a2) = \(node2)")
  }
}

// Implement negation separately
fn negate(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(n) => {
      let addr = self.heap.alloc(NNum(-n))
      self.putStack(addr)
    }
    otherwise => {
      // If not NNum, throw an error
      abort("negate: wrong kind of node \(otherwise), address \(addr) ")
    }
  }
}
```

Finally, implement branching:

```rust
fn condition(self : GState, i1 : List[Instruction], i2 : List[Instruction]) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(0) => {
      // If false, jump to i2
      self.code = append(i2, self.code)
    }
    NNum(1) => {
      // If true, jump to i1
      self.code = append(i1, self.code)
    }
    otherwise => abort("cond : \(addr) = \(otherwise)")
  }
}
```

No major adjustments are needed in the compilation part, just add some predefined programs:

```rust
let compiledPrimitives : List[(String, Int, List[Instruction])] = List::[
  // Arithmetic
  ("add", 2, List::[Push(1), Eval, Push(1), Eval, Add, Update(2), Pop(2), Unwind]),
  ("sub", 2, List::[Push(1), Eval, Push(1), Eval, Sub, Update(2), Pop(2), Unwind]),
  ("mul", 2, List::[Push(1), Eval, Push(1), Eval, Mul, Update(2), Pop(2), Unwind]),
  ("div", 2, List::[Push(1), Eval, Push(1), Eval, Div, Update(2), Pop(2), Unwind]),
  // Comparison
  ("eq",  2, List::[Push(1), Eval, Push(1), Eval, Eq,  Update(2), Pop(2), Unwind]),
  ("neq", 2, List::[Push(1), Eval, Push(1), Eval, Ne,  Update(2), Pop(2), Unwind]),
  ("ge",  2, List::[Push(1), Eval, Push(1), Eval, Ge,  Update(2), Pop(2), Unwind]),
  ("gt",  2, List::[Push(1), Eval, Push(1), Eval, Gt,  Update(2), Pop(2), Unwind]),
  ("le",  2, List::[Push(1), Eval, Push(1), Eval, Le,  Update(2), Pop(2), Unwind]),
  ("lt",  2, List::[Push(1), Eval, Push(1), Eval, Lt,  Update(2), Pop(2), Unwind]),
  // Miscellaneous
  ("negate", 1, List::[Push(0), Eval, Neg, Update(1), Pop(1), Unwind]),
  ("if",     3,  List::[Push(0), Eval, Cond(List::[Push(1)], List::[Push(2)]), Update(3), Pop(3), Unwind])
]
```

and modify the initial instruction sequence

```rust
let initialCode : List[Instruction] = List::[PushGlobal("main"), Eval]
```

## Conclusion

In the next part, we will improve the code generation for primitives and add support for data structures.
