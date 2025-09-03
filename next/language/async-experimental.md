# Async programming support

MoonBit adopts a coroutine based approach to async programming which is similar to [Kotlin](https://kotlinlang.org/docs/coroutines-overview.html).
The compiler support and concrete syntax is stable while the async library is still under development and considered experimental.

<!-- We highly appreciate any feedback or experiment with current design. -->

## Async function
Async functions are declared with the `async` keyword. 
They implicitly [`raise`](/language/error-handling.md#throwing-errors) errors 
and need to declare `noraise` explicitly if otherwise.

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async function declaration
:end-before: end async function declaration
```

Since MoonBit is a statically typed language, the compiler will track its 
asyncness, so you can just call async functions like normal functions, the
MoonBit IDE will highlight the async function call with a different style.

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async function call syntax
:end-before: end async function call syntax
```

Async functions can only be called inside async functions. 

```{warning}
Currently, async functions 
have not be supported in the body of `for .. in` loops yet, this 
will be addressed in the future.
```

## Async primitives for suspension
MoonBit provides two core primitives for `%async.suspend` and `%async.run`:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async primitive
:end-before: end async primitive
```

There two primitives are not intended for direct use by end users.
However, since MoonBit's standard library for async programming is still under development,
currently users need to bind these two primitives manually to do async programming.

There are two ways of reading these primitives:

- The coroutine reading: `%async.run` spawns a new coroutine,
  and `%async.suspend` suspends the current coroutine.
  The main difference with other languages here is:
  instead of yielding all the way to the caller of `%async.run`,
  resumption of the coroutine is handled by the callback passed to `%async.suspend`
- The delimited continuation reading: `%async.run` is the `reset` operator in
  delimited continuation, and `%async.suspend` is the `shift` operator in
  delimited continuation

Here's an example of how these two primitives work:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async example
:end-before: end async example
```

In `async_worker`, `suspend` will capture the rest of the current coroutine as two "continuation" functions, and pass them to a callback.
In the callback, calling `resume_ok` will resume execution at the point of `suspend(...)`,
all the way until the `run_async` call that start this coroutine.
calling `resume_err` will also resume execution of current coroutine,
but it will make `suspend(...)` throw an error instead of returning normally.

Notice that `suspend` type may throw error, even if `suspend` itself never throw an error directly.
This design makes coroutines cancellable at every `suspend` call: just call the corresponding `resume_err` callback.

## Integrating with JS Promise/callback based API
Since MoonBit's standard async library is still under development,
so there is no ready-to-use implementation for event loop and IO operations yet.
So the easiest way to write some async program is to use MoonBit's Javascript backend,
and reuse the event loop and IO operations of Javascript.
Here's an example of integrating MoonBit's async programming support with JS's callback based API:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async timer example
:end-before: end async timer example
```

Integrating with JS Promise is easy too:
just pass `resume_ok` as the `resolve` callback and `resume_err` as the `reject` callback to a JS promise.
