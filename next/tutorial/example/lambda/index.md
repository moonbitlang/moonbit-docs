# Lambda calculus

Functional programming rises with the fall of Moore's Law. The full utilization of multi-core processors has become an increasingly important optimization method, while functional programming also becomes more popularized with its affinity for parallel computation. The reasons behind this trend can be traced back to one of its theoretical ancestors—Lambda calculus.

Lambda calculus originated from the 1930s. Created by Turing's mentor Alonzo Church, formal systems have now evolved a vast and flourishing family tree. This article will illustrate one of its most fundamental forms: untyped Lambda calculus (which was also one of the earliest forms proposed by Alonzo Church).

## Basic rules of untyped Lambda calculus

The only actions allowed in untyped Lambda calculus are defining Lambdas (often referred to as Abstraction) and calling Lambdas (often referred to as Application). These actions constitute the basic expressions in Lambda calculus.

Most programmers are no strange to the name "Lambda expression" as most mainstream programming languages are hugely influenced by functional language paradigm. Lambdas in untyped Lambda calculus are simpler than those in mainstream programming languages. A Lambda typically looks like this: `λx.x x`, where `x` is its parameter (each Lambda can only have one parameter), `.` is the separator between the parameter and the expression defining it, and `x x` is its definition.

```{note}
Some materials may omit spaces, so the above example can be rewritten as `λx.xx`.
```

If we replace `x x` with `x(x)`, it might be more in line with the function calls we see in general languages. However, in the more common notation of Lambda calculus, calling a Lambda only requires a space between it and its parameter. Here, we call the parameter given by `x`, which is `x` itself.

The combination of the above two expressions and the variables introduced when defining Lambdas are collectively referred to as the Lambda term. In MoonBit, we use an enum type to represent it:

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: enum Term
:end-at: }
```

Concepts encountered in daily programming such as boolean values, if expressions, natural number arithmetic, and even recursion can all be implemented using Lambda expressions. However, this is not the focus of this article.

```{seealso}
Interested readers can refer to: [Programming with Nothing](https://tomstu.art/programming-with-nothing)
```

To implement an interpreter for untyped Lambda calculus, the basic things we need to understand are just two rules: Alpha conversion and Beta reduction.

**Alpha conversion** describes the fact that the structure of Lambda is crucial, and the names of variables are not that important. `λx.x` and `λfoo.foo` can be interchanged. For certain nested Lambdas with repeated variable names, such as `λx.(λx.x) x`, when renaming, the inner variables cannot be renamed. For example, the above example can be rewritten using Alpha conversion as `λy.(λx.x) y`.

**Beta reduction** focuses on handling Lambda calls. Let's take an example:

```
(λx.(λy.x)) (λs.(λz.z))
```

In untyped Lambda calculus, all that needs to be done after calling a Lambda is to substitute the parameter. In the example above, we need to replace the variable `x` with `(λs.(λz.z))`, resulting in:

```
(λy.(λs.(λz.z)))
```

## Free Variables and Variable Capture

If a variable in a Lambda term is not defined in its context, we call it a free variable. For example, in the Lambda term `(λx.(λy.fgv h))`, the variables `fgv` and `h` do not have corresponding Lambda definitions.

During Beta reduction, if the Lambda term used for variable substitution contains free variables, it may lead to a behavior called "variable capture":

```
(λx.(λy.x)) (λz.y)
```

After substitution:

```
λy.λz.y
```

The free variable in `λz.y` is treated as a parameter of some Lambda, which is obviously not what we want.

A common solution to the variable capture problem when writing interpreters is to traverse the expression before substitution to obtain a set of free variables. When encountering an inner Lambda during substitution, check if the variable name is in this set of free variables:

<!-- Pseudo code. MANUAL CHECK -->

```moonbit
// (λx.E) T => E.subst(x, T)
fn subst(self : Term, var : String, term : Term) -> Term {
  let freeVars : Set[String] = term.get_free_vars()
  match self {
    Abs(variable, body) => {
      if freeVars.contains(variable) {
        // The variable name is in the set of free variables 
        // of the current inner Lambda, indicating variable capture
        abort("subst(): error while encountering \{variable}")
      } else {
        ...
      }
    }
    ...
  }
}
```

Next, I'll introduce a less popular but somewhat convenient method: de Bruijn index.

## De Bruijn Index

De Bruijn index is a technique for representing variables in Lambda terms using integers. Specifically, it replaces specific variables with Lambdas between the variable and its original imported position.

```
λx.(λy.x (λz.z z))

λ.(λ.1 (λ.0 0))
```

In the example above, there is one Lambda `λy` between the variable `x` and its introduction position `λx`, so `x` is replaced with `1`. For variable `z`, there are no other Lambdas between its introduction position and its usage, so it is directly replaced with `0`. In a sense, the value of the de Bruijn index describes the relative distance between the variable and its corresponding Lambda. Here, the distance is measured by the number of nested Lambdas.

```{note}
The same variable may be replaced with different integers in different positions.
```

We define a new type `TermDBI` to represent Lambda terms using de Bruijn indices:

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: enum TermDBI
:end-at: }
```

However, directly writing and reading Lambda terms in de Bruijn index form is painful, so we need to write a function `bruijn()` to convert `Term` to `TermDBI`. This is also why there is still a `String` in the definition of the `TermDBI` type, so that the original variable name can be used for its `Show` implementation, making it easy to print and view the evaluation results with `println`.

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: impl Show for TermDBI
:end-at: App(t1, t2)
:append: "  }\n}"
```

To simplify implementation, if the input `Term` contains free variables, the `bruijn()` function will report an error directly. MoonBit provides a `Result[V, E]` type in the standard library, which has two constructors, `Ok(V)` and `Err(E)`, representing success and failure in computation, respectively.

```{hint}
Readers familiar with Rust should find this familiar.
```

<!-- MANUAL CHECK -->
```moonbit
fn bruijn(self : Term) -> Result[TermDBI, String]
```

We take a clumsy approach to save variable names and their associated nesting depth. First, we define the `Index` type:

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: struct Index
:end-at: }
```

Then we write a helper function to find the corresponding `depth` based on a specific `name` from `@immut/list.T[Index]`:

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:dedent:
:start-at: // Find
:end-before: fn go
```

Now we can complete the `bruijn()` function.

- Handling `Var` is the simplest, just look up the table to find the corresponding `depth`.
- `Abs` is a bit more complicated. First, add one to the `depth` of all `index` in the list (because the Lambda nesting depth has increased by one), and then add `{ name : varname, depth : 0 }` to the beginning of the list.
- `App` succeeds when both sub-items can be converted; otherwise, it returns an `Err`.

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: fn go
:end-at: go(Nil, self)
:dedent:
```

## Reduce on TermDBI

Reduction mainly deals with App, i.e., calls:

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: fn eval
:end-before: test
```

First, attempt reduction on both sub-items, then see if `eval(t1)` results in a Lambda. If so, perform one step of variable substitution (via the `subst` function) and then continue simplifying. For Lambdas (`Abs`), simply return them as they are.

The implementation of the `subst` function becomes much simpler when we don't need to consider free variables. We just need to keep track of the current depth recursively and compare it with the encountered variables. If they match, it's the variable to be replaced.

```{literalinclude} /sources/lambda-expression/src/top.mbt
:language: moonbit
:start-at: fn subst
:end-before: fn eval
```

The full code: [GitHub repository](https://github.com/moonbitlang/moonbit-docs/tree/main/next/sources/lambda-expression/src/top.mbt)

## Improvement

When mapping variable names to indices, we used the `@immut/list.T[Index]` type and updated the entire list every time we added a new Lambda. However, this is actually quite a clumsy method. I believe you can quickly realize that to store a `@immut/list.T[String]` should simply suffice. If you're interested, you can try it yourself.
