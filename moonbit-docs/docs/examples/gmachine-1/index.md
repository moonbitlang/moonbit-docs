# G-Machine 1

Lazy evaluation stands as a foundational concept in the realm of programming languages. Haskell, renowned as a purely functional programming language, boasts a robust lazy evaluation mechanism. This mechanism not only empowers developers to craft code that's both more efficient and concise but also enhances program performance and responsiveness, especially when tackling sizable datasets or intricate data streams. In this article, we'll delve into the Lazy Evaluation mechanism, thoroughly examining its principles and implementation methods, and then explore how to implement Haskell's evaluation semantics in [MoonBit](https://www.moonbitlang.com/).

## Higher-Order Functions and Performance Challenges

Higher-order functions such as `map` and `filter` often serve as many people's first impression of functional programming (although it goes far beyond these functions). They simplify many list processing tasks, but another problem emerges: using too many of these higher-order functions can lead to poor performance (because it requires multiple traversals of the list).

To enhance code efficiency, some propose leveraging compiler optimizations based on recurring patterns within higher-order functions. For instance, by rewriting `map(f, map(g, list))` as：

```
map(fn (x) { f(g(x)) }, list)
```

Nice try, but it's important to recognize that such optimization techniques have inherent limitations, particularly when navigating more complex scenarios. Consolidating all processes into a single function might circumvent the need for repeated list traversals, yet it detrimentally affects code readability and complicates the process of making modifications. Could there be a more equitable solution that balances efficiency with maintainability?

Lazy evaluation is a technique that can reduce unnecessary costs to some extent in such scenarios. This strategy can be integrated into specific data structures (for example, the Stream type added in Java 8, and the stream in the earlier Scheme language), or the entire language can be designed to be lazy (successful examples include the Miranda language of the 1980s and later by Haskell and Clean languages).

Let's first explore how lazy lists (`Stream`) can avoid multiple traversals in such cases.

## Lazy List Implementation

First, let's define its type:

```
enum Stream[T] {
  Empty
  Cons(T, () -> Stream[T])
}
```

The only real difference between `Stream[T]` and `List[T]` is in the `Cons`: the place holding the rest of the list is replaced with a parameterless function (in jargon, called a thunk). This is a simple implementation of lazy evaluation: wrapping things you don't want to compute right away in a thunk.

We also need a function to convert a regular list into a lazy list:

```
fn Stream::fromList[T](l : List[T]) -> Stream[T] {
  match l {
    Nil => Empty
    Cons(x, xs) => Cons(x, fn () { Stream::fromList(xs) })
  }
}
```

This function does not need to traverse the entire list to convert it into `Stream`. For operations that are not urgent (here, `Stream::fromList(xs)`), we wrap them directly in a thunk and return. The following `map` function will adopt this approach (though here, `xs` is already a thunk).

```
fn stream_map[X, Y](self : Stream[X], f : (X) -> Y) -> Stream[Y] {
  match self {
    Empty => Empty
    Cons(x, xs) => Cons(f(x), fn () { xs().stream_map(f) })
  }
}
```

The `take` function is responsible for performing computations, and it can extract n elements as needed.

```
fn take[T](self : Stream[T], n : Int) -> List[T] {
  if n == 0 {
    Nil
  } else {
    match self {
      Empty => Nil
      Cons(x, xs) => Cons(x, xs().take(n - 1))
    }
  }
}
```

The implementation of lazy data structures using thunks is straightforward and effectively addresses the problems mentioned above. This method requires users to explicitly indicate where in the code computation should be delayed, whereas the strategy of lazy languages is much more aggressive: it defaults to using lazy evaluation for all user-defined functions! In the following sections, we will present a minimal implementation of a lazy functional language and briefly introduce its underlying theoretical model.

## A Lazy Evaluation Language and Its Abstract Syntax Tree

The example used in this article is a lazy evaluation language, deliberately made to resemble Clojure (a Lisp dialect) and named coreF. This design choice allows for the use of Clojure's syntax highlighting in markdown. Don't worry, though the syntax might seem a bit complex at first, it is straightforward enough.

Functions are defined using the `defn` keyword:

```
(defn factorial[n] ;; n is the parameter, this function calculates the factorial of n
  (if (eq n 0) ;; The definition starts here and continues for the next three lines
    1
    (mul n (factorial (sub n 1))))
```

Referring to it as a function in general conversation is acceptable. However, when discussing lazy functional languages, we must introduce a specialized term: _Super Combinator_. In the definition of a super combinator, all free variables should be included in an initial pair of `[]`.

Execution of a coreF program begins with `main`, calling a specific super combinator as if replacing it with its definition.

```
(defn main[] (factorial 42))
```

Super combinators without parameters, such as `main`, are referred to by a specific term: _Constant Applicative Forms (CAF)_.

coreF also possesses several language features, including custom data structures, `case` expressions for dismantling structures, and `let` and `letrec` for the declaration of local variables. However, the scope of this article is limited to the aforementioned features (actually, even less, as built-in functions like `eq`, `mul`, `sub`, etc., are planned for future implementation).

coreF excludes anonymous functions because anonymous functions introduce extra free variables. Removing them requires an additional transformation step: lambda lifting. This technique can transform a lambda expression into an external Super Combinator, but this is not a main point of lazy evaluation, hence its omission here.

Super combinators will eventually be parsed into `ScDef[String]`, but writing a parser is a tedious task. I will provide it along with the final code.

```
enum RawExpr[T] {
  Var(T)
  Num(Int)
  Constructor(Int, Int) // tag, arity
  App(RawExpr[T], RawExpr[T])
  Let(Bool, List[(T, RawExpr[T])], RawExpr[T]) // isRec, Defs, Body
  Case(RawExpr[T], List[(Int, List[T], RawExpr[T])])
}

struct ScDef[T] {
  name : String
  args : List[T]
  body : RawExpr[T]
} derive (Show)
```

Additionally, some predefined coreF programs are required.

```
let preludeDefs : List[ScDef[String]] = {
  let id = ScDef::new("I", arglist1("x"), Var("x")) // id x = x
  let k = ScDef::new("K", arglist2("x", "y"), Var("x")) // K x y = x
  let k1 = ScDef::new("K1", arglist2("x", "y"), Var("y")) // K1 x y = y
  let s = ScDef::new("S", arglist3("f", "g", "x"), App(App(Var("f"), Var("x")), App(Var("g"), Var("x")))) // S f g x = f x (g x)
  let compose = ScDef::new("compose", arglist3("f", "g", "x"), App(Var("f"), App(Var("g"), Var("x")))) // compose f g x = f (g x)
  let twice = ScDef::new("twice", arglist1("f"), App(App(Var("compose"), Var("f")), Var("f"))) // twice f = compose f f
  Cons(id, Cons(k, Cons(k1, Cons(s, Cons(compose, Cons(twice, Nil))))))
}
```

## Why Graph

In the coreF language, expressions (not `RawExpr[T]` mentioned earlier, but runtime expressions) are stored in memory in the form of a graph rather than a tree when being evaluated.)

Why is this approach taken? Let's examine this through a program example:

```
(defn square[x]  (mul x x))
(defn main[] (square (square 3)))
```

If we evaluate according to the conventional expression tree, it would be reduced to:

```
(mul (square 3) (square 3))
```

In this case, `(square 3)` would be evaluated twice, which is certainly not desirable for lazy evaluation.

To illustrate this more clearly, let's make a somewhat improper analogy using MoonBit code:

```
fn square(thunk : () -> Int) -> Int {
  thunk() * thunk()
}
```

To represent the program using a graph is to facilitate sharing of computation results and avoid redundant calculations. To achieve this purpose, it's crucial to implement an in-place update algorithm when reducing the graph. Regarding in-place update, let's simulate it using MoonBit code:

```
enum LazyData[T] {
  Waiting(() -> T)
  Done(T)
}

struct LazyRef[T] {
  mut data : LazyData[T]
}

fn extract[T](self : LazyRef[T]) -> T {
  match self.data {
    Waiting(thunk) => {
      let value = thunk()
      self.data = Done(value) // in-place update
      value
    }
    Done(value) => value
  }
}

fn square(x : LazyRef[Int]) -> Int {
  x.extract() * x.extract()
}
```

Regardless of which side executes the `extract` method first, it will update the referenced mutable field and replace its content with the computed result. Therefore, there's no need to recompute it during the second execution of the `extract` method.

## Conventions

Before delving into how graph reduction works, let's establish some key terms and basic facts. We'll continue using the same program as an example:

```
(defn square[x]  (mul x x)) ;; multiplication
(defn main[] (square (square 3)))
```

- Built-in primitives like `mul` are predefined operations.

* Evaluating an expression (of course, lazy) and updating its corresponding node in the graph in place is called reduction.
* `(square 3)` is a reducible expression (often abbreviated as redex), consisting of `square` and its argument. It can be reduced to `(mul 3 3)`. `(mul 3 3)` is also a redex, but it's a different type of redex compared to `(square 3)` because `square` is a user-defined combinator while `mul` is an implemented built-in primitive.
* The reduction result of `(mul 3 3)` is the expression `9`, which cannot be further reduced. Such expressions that cannot be further reduced are called Normal forms.
* An expression may contain multiple sub-expressions (e.g., `(mul (add 3 5) (mul 7 9))`). In such cases, the order of reduction of expressions is crucial – some programs only halt under specific reduction orders.

- There's a special reduction order that always selects the outermost redex for reduction, known as _normal order reduction_. This reduction order will be uniformly adopted in the following discussion.

So, the graph reduction can be described with the following pseudocode:

```
While there exist reducible expressions in the graph {
    Select the outermost reducible expression.
    Reduce the expression.
    Update the graph with the result of reduction.
}
```

Dizzy now? Let's find a few examples to demonstrate how to perform reductions on paper.

**Step 1: Find the next redex**

The execution of the entire program starts from the `main` function.

```
(defn square[x]  (mul x x))
(defn main[] (add 33 (square 3)))
```

`main` itself is a CAF - the simplest kind of redex. If we perform the substitution, the current expression to be handled is:

```
(add 33 (square 3))
```

According to the principle of finding the outermost redex, it seems like we've immediately found the redex formed by `add` and its two parameters (let's assume it for now).

But wait! Due to the presence of default currying, the abstract syntax tree corresponding to this expression is actually composed of multiple nested `App` nodes. It roughly looks like this (simplified for readability):

```
App(App(add, 33), square3)
```

This chain-like structure from `add` to the outermost `App` node is called the "Spine"

Going back to check, `add` is an internally defined primitive. However, since its second argument `(square 3)` is not in normal form, we cannot reduce it (adding an unevaluated expression to an integer seems a bit absurd). So, we can't definitively say that `(add 33 (square 3))` is a redex; it's just the outermost function application. To reduce it, we must first reduce `(square 3)`.

**Step 2: Reduce**

Since `square` is a user-defined super combinator, reducing `(square 3)` involves only parameter substitution.

If a redex has fewer arguments than required by the super combinator, which is common in higher-order functions, consider the example of tripling all integers in a list.

```
(map (mul 3) list-of-int)
```

Here, `(mul 3)` cannot be treated as a redex because it lacks sufficient arguments, making it a `weak head normal form` (often abbreviated as WHNF). In this situation, even if its sub-expressions contain redexes, no action is needed.

**Step 3: Update**

This step only affects execution efficiency and can be skipped during paper deductions.

These operations are easy to perform on paper (when the amount of code doesn't exceed half a sheet), but when we switch to computers, how do we translate these steps into executable code?

To answer this question, pioneers in the world of lazy evaluation programming languages have proposed various **abstract machines** for modeling lazy evaluation. These include:

- G-Machine
- Three Instruction Machine
- ABC Machine (used by the Clean language)
- Spineless Tagless G-Machine (abbreviated as STG, used by Haskell language)

They are execution models used to guide compiler implementations. It's important to note that, unlike various popular virtual machines today (such as the JVM), abstract machines are more like intermediate representations (IR) for compilers. Taking Haskell's compiler GHC as an example, after generating STG (Spineless Tagless G-Machine) code, it doesn't directly pass it to an interpreter for execution. Instead, it further transforms it into LLVM, C code, or machine code based on the selected backend.

To simplify implementation, this article will directly use MoonBit to write an interpreter for G-Machine instructions, starting from a minimal example and gradually adding more features.

## **G-Machine Overview**

While the G-Machine is an abstract machine for lazy functional languages, its structure and concepts are not significantly different from what one encounters when writing general imperative languages. It also features structures like heap and stack, and its instructions are executed sequentially. Some key differences include:

- The basic unit of memory in the heap is not bytes, but graph nodes.
- The stack only contains pointers to addresses in the heap, not actual data.

> This design may not be practical, but it's relatively simple.

In coreF, super combinators are compiled into a series of G-Machine instructions. These instructions can be roughly categorized as follows:

- Access Data Instructions, For example, `PushArg` (access function arguments), and `PushGlobal` (access other super combinators).
- Construct/update graph nodes in the heap, like `MkApp`, `PushInt`, `Update`
- Clean up the `Pop` instruction of the unused addresses from the stack.
- Express control flow with the `Unwind` instruction

## Dissecting the G-Machine State

In this simple version of the G-Machine, the state includes:

- Heap: This is where the expression graph and the sequences of instructions corresponding to super combinators are stored.

```
type Addr Int derive(Eq, Show) // Use the 'type' keyword to encapsulate an address type.

enum Node { // Describe graph nodes with an enumeration type.
  NNum(Int)
  NApp(Addr, Addr) // The application node
  NGlobal(Int, List[Instruction]) // To store the number of parameters and the corresponding sequence of instructions for a super combinator.
  NInd(Addr) // The Indirection node，The key component of implementing lazy evaluation
} derive (Eq)

struct GHeap { // The heap uses an array, and the space with None content in the array is available as free memory.
  mut objectCount : Int
  memory : Array[Option[Node]]
}

// Allocate heap space for nodes.
fn alloc(self : GHeap, node : Node) -> Addr {
  let heap = self
  // Assuming there is still available space in the heap.
  fn next(n : Int) -> Int {
    (n + 1) % heap.memory.length()
  }
  fn free(i : Int) -> Bool {
    match heap.memory[i] {
      None => true
      _    => false
    }
  }
  let mut i = heap.objectCount
  while not(free(i)) {
    i = next(i)
  }
  heap.memory[i] = Some(node)
  return Addr(i)
}
```

- Stack: The stack only holds addresses pointing to the heap. A simple implementation can use `List[Addr]`.
- Global Table: It's a mapping table that records the names of super combinators (including predefined and user-defined) and their corresponding addresses as `NGlobal` nodes. Here I implement it using a Robin Hood hash table.
- Current code sequence to be executed.
- Execution status statistics: A simple implementation involves calculating how many instructions have been executed.

```
type GStats Int

let statInitial : GStats = GStats(0)

fn statInc(self : GStats) -> GStats {
  let GStats(n) = self
  GStats(n + 1)
}

fn statGet(self : GStats) -> Int {
  let GStats(n) = self
  return n
}
```

The entire state is represented using the type `GState`.

```

struct GState {
  stack : List[Addr]
  heap : GHeap
  globals : RHTable[String, Addr]
  code : List[Instruction]
  stats : GStats
}

fn putStack(self : GState, addr : Addr) {
  self.stack = Cons(addr, self.stack)
}

fn putCode(self : GState, is : List[Instruction]) {
  self.code = append(is, self.code)
}

fn pop1(self : GState) -> Addr {
  match self.stack {
    Cons(addr, reststack) => {
      self.stack = reststack
      addr
    }
    Nil => {
      abort("pop1: stack size smaller than 1")
    }
  }
}

fn pop2(self : GState) -> (Addr, Addr) {
  // Pop 2 pops the top two elements from the stack.
  // Returns (the first, the second).
  match self.stack {
    Cons(addr1, Cons(addr2, reststack)) => {
      self.stack = reststack
      (addr1, addr2)
    }
    otherwise => {
      abort("pop2: stack size smaller than 2")
    }
  }
}
```

Now, we can map each step of the graph reduction algorithm we deduced on paper to this abstract machine:

- At the initial state of the machine, all compiled super combinators have been placed in `NGlobal` nodes on the heap. At this point, the current code sequence in the G-Machine contains only two instructions. The first instruction pushes the address of the `main` node onto the stack, and the second instruction loads the corresponding code sequence of `main` into the current code sequence.
- The corresponding code sequence of `main` is instantiated on the heap, where nodes are allocated and data is loaded accordingly, ultimately constructing a graph in memory. This process is referred to as "instantiating" `main`. Once instantiation is complete, the address of the entry point of this graph is pushed onto the stack.
- After instantiation is finished, you need to update graph nodes (since `main` has no parameters, there is no need to clean up residual unused addresses in the stack) and find the next redex to clean up.

Now, we can map each step of the graph reduction algorithm we deduced on paper to this abstract machine:

- At the initial state of the machine, all compiled super combinators have been placed in `NGlobal` nodes on the heap. At this point, the current code sequence in the G-Machine contains only two instructions. The first instruction pushes the address of the `main` node onto the stack, and the second instruction loads the corresponding code sequence of `main` into the current code sequence.
- The corresponding code sequence of `main` is instantiated on the heap, where nodes are allocated and data is loaded accordingly, ultimately constructing a graph in memory. This process is referred to as "instantiating" `main`. Once instantiation is complete, the address of the entry point of this graph is pushed onto the stack.
- After instantiation is finished, cleanup work is done, which involves updating graph nodes (since `main` has no parameters, there is no need to clean up residual unused addresses in the stack) and finding the next redex.

All of these tasks have corresponding instruction implementations.

## Corresponding Effect of Each Instruction

The highly simplified G-Machine currently consists of 7 instructions.

```
enum Instruction {
  Unwind
  PushGlobal(String)
  PushInt(Int)
  PushArg(Int)
  MkApp
  Update(Int)
  Pop(Int)
} derive (Eq, Debug, Show)
```

The `PushInt` instruction is the simplest. It allocates an `NNum` node on the heap and pushes its address onto the stack.

```
fn pushint(self : GState, num : Int) {
  let addr = self.heap.alloc(NNum(num))
  self.putStack(addr)
}
```

The `PushGlobal` instruction retrieves the address of the specified super combinator from the global table and then pushes the address onto the stack.

```
fn pushglobal(self : GState, name : String) {
  let sc = self.globals[name]
  match sc {
    None => abort("pushglobal(): cant find super combinator \(name)")
    Some(addr) => {
      self.putStack(addr)
    }
  }
}
```

The `PushArg` instruction is a bit more complex. It has specific requirements regarding the layout of addresses on the stack: the first address should point to the super combinator node, followed by n addresses pointing to N `NApp` nodes. `PushArg` retrieves the Nth parameter, starting from the `offset + 1`.

```
fn pusharg(self : GState, offset : Int) {
  // Skip the first super  combinator node.
  // Access the (offset + 1)th NApp node
  let appaddr = nth(self.stack, offset + 1)
  let arg = match self.heap[appaddr] {
    NApp(_, arg) => arg
    otherwise => abort("pusharg: stack offset \(offset) address \(appaddr) node \(otherwise), not a applicative node")
  }
  self.putStack(arg)
}
```

The `MkApp` instruction takes two addresses from the top of the stack, constructs an `NApp` node, and pushes its address onto the stack.

```
fn mkapp(self : GState) {
  let (a1, a2) = self.pop2()
  let appaddr = self.heap.alloc(NApp(a1, a2))
  self.putStack(appaddr)
}
```

The `Update` instruction assumes that the first address on the stack points to the current redex's evaluation result. It skips the addresses of the immediately following super combinator nodes and replaces the Nth `NApp` node with an indirect node pointing to the evaluation result. If the current redex is a CAF, it directly replaces its corresponding `NGlobal` node on the heap. From this, we can see why in lazy functional languages, there is not much distinction between functions without parameters and ordinary variables.

```
fn update(self : GState, n : Int) {
  let addr = self.pop1()
  let dst = nth(self.stack, n)
  self.heap[dst] = NInd(addr)
}
```

The `Unwind` instruction in the G-Machine is akin to an evaluation loop. It has several branching conditions based on the type of node corresponding to the address at the top of the stack:

- For `Nnum` nodes: Do nothing.
- For `NApp` nodes: Push the address of the left node onto the stack and `Unwind` again.
- For `NGlobal` nodes: If there are enough parameters on the stack, load this super combinator into the current code.
- For `NInd` nodes: Push the address contained within this indirect node onto the stack and Unwind again.

```
fn unwind(self : GState) {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(_) => self.putStack(addr)
    NApp(a1, _) => {
      self.putStack(addr)
      self.putStack(a1)
      self.putCode(Cons(Unwind, Nil))
    }
    NGlobal(_, n, c) => {
      if length(self.stack) < n {
        abort("Unwinding with too few arguments")
      } else {
        self.putStack(addr)
        self.putCode(c)
      }
    }
    NInd(a) => {
      self.putStack(a)
      self.putCode(Cons(Unwind, Nil))
    }
    otherwise => abort("unwind() : wrong kind of node \(otherwise), address \(addr)")
  }
}
```

The `Pop` instruction pops N addresses, eliminating the need for a separate function implementation.

## Compiling Super Combinators into Instruction Sequences

In the G-Machine Overview section, we roughly described the behavior of compiled super combinators. Now we can precisely describe the compilation process of super combinators.

Firstly, before the instruction sequence of a compiled super combinator is executed, there must be certain addresses already present in the stack:

- The topmost address points to an `NGlobal` node (the super combinator itself).
- Following are N addresses (N being the number of parameters for this super combinator), pointing to a series of App nodes - corresponding exactly to the spine of a redex. The bottommost address in the stack points to the outermost App node of the expression, and the rest follow suit.

When compiling a super combinator, we need to maintain an environment that allows us to find the relative position of parameters in the stack during the compilation process by their names. Additionally, since clearing the preceding N+1 addresses is necessary after completing the instantiation of a super combinator, the number of parameters N needs to be passed as well.

> Here, "parameters" refer to addresses pointing to App nodes on the heap, and the actual parameter addresses can be accessed through the pusharg instruction.

```
fn compileSC(self : ScDef[String]) -> (String, Int, List[Instruction]) {
  let name = self.name
  let body = self.body
  let mut arity = 0
  fn gen_env(i : Int, args : List[String]) -> List[(String, Int)] {
    match args {
      Nil => {
        arity = i
        return Nil
      }
      Cons(s, ss) => Cons((s, i), gen_env(i + 1, ss))
    }
  }
  let env = gen_env(0, self.args)
  (name, arity, compileR(body, env, arity))
}
```

The `compileR` function generates code for instantiating super combinators by calling the `compileC` function, and then appends three instructions:

- `Update(N)`: Updates the original redex in the heap to an `NInd` node, which then points to the newly instantiated super combinator.
- `Pop(N)`: Clears the stack of redundant addresses.
- `Unwind`: Searches for the next redex to start the next reduction.

```
fn compileR(self : RawExpr[String], env : List[(String, Int)], arity : Int) -> List[Instruction] {
  if arity == 0 {
    // The Pop 0 instruction does nothing in practice, so it is not generated when the arity is 0.
    append(compileC(self, env), from_array([Update(arity), Unwind]))
  } else {
    append(compileC(self, env), from_array([Update(arity), Pop(arity), Unwind]))
  }
}
```

When compiling the definition of super combinators, a rather crude approach is used: if a variable is not a parameter, it is treated as another super combinator (writing it incorrectly will result in a runtime error). For function application, the right-hand expression is compiled first, then all offsets corresponding to parameters in the environment are incremented (because an extra address pointing to the instantiated right-hand expression is added to the top of the stack), then the left-hand expression is compiled, and finally the `MkApp` instruction is added.

```
fn compileC(self : RawExpr[String], env : List[(String, Int)]) -> List[Instruction] {
  match self {
    Var(s) => {
      match lookupENV(env, s) {
        None => from_array([PushGlobal(s)])
        Some(n) => from_array([PushArg(n)])
      }
    }
    Num(n) => from_array([PushInt(n)])
    App(e1, e2) => {
      append(compileC(e2, env), append(compileC(e1, argOffset(1, env)), from_array([MkApp])))
    }
    _ => abort("not support yet")
  }
}
```

## Running the G-Machine

Once the super combinators are compiled, they need to be placed on the heap (along with adding their addresses to the global table). This can be done recursively.

```
fn buildInitialHeap(scdefs : List[(String, Int, List[Instruction])]) -> (GHeap, RHTable[String, Addr]) {
  let heap = { objectCount : 0, memory : Array::make(10000, None) }
  let globals = RHTable::new(50)
  fn go(lst : List[(String, Int, List[Instruction])]) {
    match lst {
      Nil => ()
      Cons((name, arity, instrs), rest) => {
        let addr = heap.alloc(NGlobal(name, arity, instrs))
        globals[name] = addr
        go(rest)
      }
    }
  }
  go(scdefs)
  return (heap, globals)
}
```

Define a function "step" that updates the state of the G-Machine by one step, returning false if the final state has been reached.

```
fn step(self : GState) -> Bool {
  match self.code {
    Nil => { return false }
    Cons(i, is) => {
      self.code = is
      self.statInc()
      match i {
        PushGlobal(f) => self.pushglobal(f)
        PushInt(n) => self.pushint(n)
        PushArg(n) => self.pusharg(n)
        MkApp => self.mkapp()
        Unwind => self.unwind()
        Update(n) => self.update(n)
        Pop(n) => { self.stack = drop(self.stack, n) } // without the need for additional functions
      }
      return true
    }
  }
}
```

Additionally, define a function "reify" that continuously executes the "step" function until the final state is reached.

```
fn reify(self : GState) {
  if self.step() {
    self.reify()
  } else {
    let stack = self.stack
    match stack {
      Cons(addr, Nil) => {
        let res = self.heap[addr]
        println("\(res)")
      }
      _ => abort("wrong stack \(stack)")
    }
  }
}
```

Combine the above components.

```
fn run(codes : List[String]) {
  fn parse_then_compile(code : String) -> (String, Int, List[Instruction]) {
    let code = TokenStream::new(code)
    let code = parseSC(code)
    let code = compileSC(code)
    return code
  }
  let codes = append(map(parse_then_compile, codes), map(compileSC, preludeDefs))
  let (heap, globals) = buildInitialHeap(codes)
  let initialState : GState = {
    heap : heap,
    stack : Nil,
    code : initialCode,
    globals : globals,
    stats : initialStat
  }
  initialState.reify()
}
```

## Conclusion

The features of the G-Machine we've constructed so far are too limited to run even a somewhat decent program. In the next article, we will incrementally add features such as primitives and custom data structures. Towards the end, we'll introduce lazy evaluation techniques after covering the G-Machine.

## Reference

Peyton Jones, Simon & Lester, David. (2000). Implementing functional languages: a tutorial.
