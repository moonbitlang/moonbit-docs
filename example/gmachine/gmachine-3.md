# G-Machine 3

This article is the third in a series on implementing Haskell's lazy evaluation in MoonBit. In the previous article, we learned how to compile `let` expressions and how to implement basic arithmetic and comparison operations. In this article, we will implement a context-based optimization method and add support for data structures.

## Tracking Context

Let's review how we implemented primitives in the [last tutorial](gmachine-2.md).

```moonbit
let compiled_primitives : List[(String, Int, List[Instruction])] = @list.of([
    // Arith
    (
      "add",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Add,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "sub",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Sub,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "mul",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Mul,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "div",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Div,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    // Compare
    (
      "eq",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Eq,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "neq",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Ne,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "ge",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Ge,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "gt",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Gt,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "le",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Le,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    (
      "lt",
      2,
      @list.of([
        Push(1),
        Eval,
        Push(1),
        Eval,
        Lt,
        Update(2),
        Pop(2),
        Unwind,
      ]),
    ),
    // MISC
    (
      "negate",
      1,
      @list.of([Push(0), Eval, Neg, Update(1), Pop(1), Unwind]),
    ),
    (
      "if",
      3,
      @list.of([
        Push(0),
        Eval,
        Cond(@list.of([Push(1)]), @list.of([Push(2)])),
        Update(3),
        Pop(3),
        Unwind,
      ]),
    ),
  ],
)
```

This implementation introduces many `Eval` instructions, but they are not always necessary. For example:

```clojure
(add 3 (mul 4 5))
```

The two arguments of `add` are already in WHNF (Weak Head Normal Form) before executing `Eval`. Therefore, the `Eval` instructions here are redundant.

One feasible optimization method is to consider the context when compiling expressions. For example, `add` requires its arguments to be evaluated to WHNF, so its arguments are in a strict context during compilation. By doing this, we can identify some expressions that can be safely compiled with strict evaluation (only a subset).

- An expression in a supercombinator definition is in a strict context.
- If `(op e1 e2)` is in a strict context (where `op` is a primitive), then `e1` and `e2` are also in a strict context.
- If `(let (.....) e)` is in a strict context, then `e` is also in a strict context (but the expressions corresponding to the local variables are not, as `e` may not need their results).

We use the `compileE` function to implement compilation in a strict context, ensuring that *the value at the top of the stack is always in WHNF*.

For the default branch, we simply add an `Eval` instruction after the result of `compileC`.

```moonbit
_ => self.compileC(env) + @list.of([Eval])
```

Constants are pushed directly.

```moonbit
Num(n) => @list.of([PushInt(n)])
```

For `let/letrec` expressions, the specially designed `compileLet` and `compileLetrec` become useful. Compiling a `let/letrec` expression in a strict context only requires using `compileE` to compile its main expression.

```moonbit
Let(rec, defs, e) =>
  if rec {
    compileLetrec(RawExpr::compileE, defs, e, env)
  } else {
    compileLet(RawExpr::compileE, defs, e, env)
  }
```

The `if` and `negate` functions, with 3 and 1 arguments respectively, require special handling.

```moonbit
App(App(App(Var("if"), b), e1), e2) => {
  let condition = b.compileE(env)
  let branch1 = e1.compileE(env)
  let branch2 = e2.compileE(env)
  condition + @list.of([Cond(branch1, branch2)])
}
App(Var("negate"), e) => e.compileE(env) + @list.of([Neg])
```

Basic binary operations can be handled uniformly through a lookup table. First, construct a hash table called `builtinOpS` to query the corresponding instructions by the name of the primitive.

```moonbit
let builtinOpS : @hashmap.HashMap[String, Instruction] = {
  let table = @hashmap.new(capacity=50)
  table["add"] = Add
  table["mul"] = Mul
  table["sub"] = Sub
  table["div"] = Div
  table["eq"] = Eq
  table["neq"] = Ne
  table["ge"] = Ge
  table["gt"] = Gt
  table["le"] = Le
  table["lt"] = Lt
  table
}
```

The rest of the handling is not much different.

```moonbit
App(App(Var(op), e0), e1) =>
  match builtinOpS.get(op) {
    None => self.compileC(env) + @list.of([Eval])
    Some(instr) => {
      let code1 = e1.compileE(env)
      let code0 = e0.compileE(argOffset(1, env))
      code1 + code0 + @list.of([instr])
    }
  }
```

Are we done? It seems so, but there's another WHNF besides integers: partially applied functions.

A partial application is when the number of arguments is insufficient. This situation is common in higher-order functions, for example:

```clojure
(map (add 1) listofnumbers)
```

Here, `(add 1)` is a partial application.

To ensure that the code generated by the new compilation strategy works correctly, we need to modify the implementation of the `Unwind` instruction for the `NGlobal` branch. When the number of arguments is insufficient and the dump has saved stacks, we should only retain the original redex and restore the stack.

```moonbit
NGlobal(_, n, c) => {
  let k = self.stack.length()
  if k < n {
    match self.dump {
      Empty => abort("Unwinding with too few arguments")
      More((i, s), tail=rest) => {
        // a1 : ...... : ak
        // ||
        // ak : s
        self.stack = self.stack.drop(k - 1) + s
        self.dump = rest
        self.code = i
      }
    }
  } else {
    if n != 0 {
      self.rearrange(n)
    } else {
      self.put_stack(addr)
    }
    self.put_code(c)
  }
}
```

This context-based strictness analysis technique is useful but cannot do anything with supercombinator calls. Here we briefly introduce a strictness analysis technique based on boolean operations, which can analyze which arguments of a supercombinator call should be compiled using strict mode.

We first define a concept: bottom, which conceptually represents a value that never terminates or causes an exception. For a supercombinator `f a[1] ...... a[n]`, if one argument `a[i]` satisfies `a[i] = bottom`, then `f a[1] .... a[i] .... a[n] = bottom` (other arguments are not bottom). This indicates that no matter how complex the internal control flow of `f` is, it **must** need the result of argument `a[i]` to get the final result. Therefore, a`[i]` should be strictly evaluated.

> If this condition is not met, it does not necessarily mean that the argument is not needed at all; it may be used only in certain branches and its use is determined at runtime. Such an argument is a typical example of one that should be lazily evaluated.

Let's consider bottom as `false` and non-bottom values as `true`. In this way, all functions in coreF can be considered boolean functions. Take `abs` as an example:

```clojure
(defn abs[n]
  (if (lt n 0) (negate n) n))
```

We analyze how to translate it into a boolean function from top to bottom:

- For an expression like `(if x y z)`, x must be evaluated, but only one of `y` or `z` needs to be evaluated. This can be translated into `x and (y or z)`. Taking the example of the function above, if `n` is bottom, then the condition `(lt n 0)` is also bottom, and thus the result of the entire expression is also bottom.
- For primitive expressions, using `and` for all parts is sufficient.

To determine whether a parameter needs to be compiled strictly, you can convert the above condition into a Boolean function: `a[i] = false` implies `f a[1] .... a[i] .... a[n] = false` (with all other parameters being true).

> This is essentially a method of program analysis called "abstract interpretation."

## Custom Data Structures

The data structure type definition in Haskell is similar to the `enum` in MoonBit. However, since CoreF is a simple toy language used to demonstrate lazy evaluation, it does not allow custom data types. The only built-in data structure is the lazy list.

```clojure
(defn take[n l]
  (case l
    [(Nil) Nil]
    [(Cons x xs)
      (if (le n 0)
        Nil
        (Cons x (take (sub n 1) xs)))]))
```

As shown above, you can use the `case` expression for simple pattern matching on lists.

The corresponding graph node for a list is `NConstr(Int, List[Addr])`, which consists of two parts:

- A tag for different value constructors: the tag for `Nil` is 0, and the tag for `Cons` is 1.
- A list of addresses for storing substructures, whose length corresponds to the number of parameters (arity) of a value constructor.

> This graph node structure can be used to implement various data structures, but CoreF does not have a type system. For demonstration purposes, only lazy lists are implemented.

We need to add two instructions, `Split` and `Pack`, to deconstruct and construct lists.

```moonbit
fn GState::pack(self : GState, t : Int, n : Int) -> Unit {
  let addrs = self.stack.take(n)
  self.stack = self.stack.drop(n)
  let addr = self.heap.alloc(NConstr(t, addrs))
  self.put_stack(addr)
}

fn GState::split(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NConstr(_, addrs) =>
      // n == addrs.length()
      self.stack = addrs + self.stack
    _ => panic()
  }
}
```

Additionally, a `CaseJump` instruction is needed to implement the `case` expression.

```moonbit
fn GState::casejump(self : GState, table : List[(Int, List[Instruction])]) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NConstr(t, _) =>
      match table.lookup(t) {
        None => abort("casejump")
        Some(instrs) => {
          self.code = instrs + self.code
          self.put_stack(addr)
        }
      }
    otherwise => abort("casejump(): addr = \{addr} node = \{otherwise}")
  }
}
```

After adding the above instructions, we need to modify the `compileC` and `compileE` functions. Since the object matched by the `case` expression needs to be evaluated to WHNF, only the `compileE` function can compile it.

```moonbit
App(App(Constructor(tag=1, arity=2), x), xs) =>
  // Cons(x, xs)
  xs.compileC(env) + x.compileC(argOffset(1, env)) + @list.of([Pack(1, 2)])
// Empty
Constructor(tag=0, arity=0) => @list.of([Pack(0, 0)])
```

```moonbit
Case(e, alts) =>
  e.compileE(env) + @list.of([CaseJump(compileAlts(alts, env))])
Constructor(tag=0, arity=0) =>
  // Empty
  @list.of([Pack(0, 0)])
App(App(Constructor(tag=1, arity=2), x), xs) =>
  // Cons(x, xs)
  xs.compileC(env) + x.compileC(argOffset(1, env)) + @list.of([Pack(1, 2)])
```

At this point, a new problem arises. Previously, printing the evaluation result only needed to handle simple `NNum` nodes, but `NConstr` nodes have substructures. When the list itself is evaluated to WHNF, its substructures are mostly unevaluated `NApp` nodes. We need to add a `Print` instruction, which will recursively evaluate and write the result into the `output` component of `GState`.

```moonbit
fn GState::gprint(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(n) => {
      self.output.write_string(n.to_string())
      self.output.write_char(' ')
    }
    NConstr(0, Empty) => self.output.write_string("Nil")
    NConstr(1, More(addr1, tail=More(addr2, tail=Empty))) => {
      self.code = @list.of([Instruction::Eval, Print, Eval, Print]) +
        self.code
      self.put_stack(addr2)
      self.put_stack(addr1)
    }
    _ => panic()
  }
}
```

Finally, change the initial code of the G-Machine to:

```moonbit
let initialState : GState = {
  output: @buffer.new(size_hint=60),
  heap,
  stack: @list.empty(),
  code: @list.of([PushGlobal("main"), Eval, Print]),
  globals,
  stats: 0,
  dump: @list.empty(),
}
```

Now, we can write some classic functional programs using lazy lists, such as the infinite Fibonacci sequence:

```clojure
(defn fibs[] (Cons 0 (Cons 1 (zipWith add fibs (tail fibs)))))
```

After introducing data structures, strictness analysis becomes more complex. For lazy lists, there are various evaluation modes:

- Fully strict (requires the list to be finite and all elements to be non-bottom).
- Fully lazy.
- Head strict (the list can be infinite, but its elements cannot be bottom).
- Tail strict (the list must be finite, but its elements can be bottom).

Moreover, the context in which a function is used can change the evaluation mode of its parameters (it cannot be analyzed in isolation and requires cross-function analysis). Such complex strictness analysis usually employs projection analysis techniques. Relevant literature includes:

- Projections for Strictness Analysis
- Static Analysis and Code Optimizations in Glasgow Haskell Compiler
- Implementing Projection-based Strictness Analysis
- Theory and Practice of Demand Analysis in Haskell

## Epilogue

Lazy evaluation can reduce runtime redundant calculations, but it also introduces new problems, such as:

- The notorious side effect order issue.
- Excessive redundant nodes. Some computations that are not shared still store their results on the heap, which is detrimental to utilizing the CPU's caching mechanism.

The representative of lazy evaluation languages, Haskell, offers a controversial solution to the side effect order problem: Monads. This solution has some value for eagerly evaluated languages as well, but many online tutorials emphasize its mathematical background too much and fail to explain how to use it effectively.

Idris2, Haskell's successor (which is no longer a lazy language), retains Monads and introduces another mechanism for handling side effects: Algebraic Effects.

The Spineless G-Machine designed by SPJ improved the problem of excessive redundant nodes, and its successor, the STG, unified the data layout of different types of nodes.

In addition to improvements in abstract machine models, GHC's optimization of Haskell programs heavily relies on inline-based optimizations and projection analysis-based strictness analysis techniques.

In 2004, several GHC designers discovered that the previous push-enter model, where parameters are pushed onto the stack and then a function is called, was less effective than the eval-apply model, where the responsibility is handed to the caller. They published a paper titled "Making a Fast Curry: Push/Enter vs. Eval/Apply for Higher-order Languages."

In 2007, Simon Marlow found that jump and execute code in the tagless design significantly affected the performance of modern CPU branch predictors. The paper "*Faster laziness using dynamic pointer tagging*" described several solutions.

Lazy purely functional languages have shown many interesting possibilities, but they have also faced much criticism and reflection. Nevertheless, it is undoubtedly an intriguing technology!
