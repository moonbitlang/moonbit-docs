# Async programming support

MoonBit adopts a coroutine based approach to async programming which is similar to [Kotlin](https://kotlinlang.org/docs/coroutines-overview.html).
Asynchronous programming in MoonBit consists of two parts: compiler support for `async` functions, and the official async runtime `moonbitlang/async`.
Currently, `moonbitlang/async` supports native backend best, has limit support for JavaScript backend, and does not support WebAssembly backend yet.
The API of `moonbitlang/async` is not considered stable, and may change in the future.

<!-- We highly appreciate any feedback or experiment with current design. -->

## Getting started
To use `moonbitlang/async` for asynchronous programming,
you should first run `moon add moonbitlang/async` in your project
to add `moonbitlang/async` as a dependency of your project.
You may also want to set `"preferred-target": "native"` in `moon.mod.json`.
Now, import `moonbitlang/async` and other packages in the `moonbitlang/async` library in `moon.pkg`,
and the asynchronous programming API should be available in your packages.

The list of packages in `moonbitlang/async` and their detailed documentation
can be found on [mooncakes.io](https://mooncakes.io/docs/moonbitlang/async),
and some useful [examples](https://github.com/moonbitlang/async/tree/main/examples) on the GitHub repo of `moonbitlang/async`.
This article will introduce some of the basic concept of `moonbitlang/async` and some of the most important API.

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
If you open the above code snippet with the MoonBit IDE,
you should see the `@http.get` function rendered in italic style with an underline.

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async function call syntax
:end-before: end async function call syntax
```

Async functions can only be called inside async functions.
Calling `async` function will result in the caller being blocked
and waiting for the callee to return, similar to `await` in many other languages.

MoonBit has first-class support for asynchronous programming.
You can use `async fn main` to declare an asynchronous program entry,
or use `async test` to write test for asynchronous code.
Asynchronous tests are automatically run in parallel by default.
Notice that you must import `moonbitlang/async` in your package to use `async fn main` and `async test`.

## Structured concurrency and task group
If an asynchronous program only call async function directly (i.e. `await`),
then the control flow of the program is linear,
and the program is no different from a normal, synchronous programming.
The fundamental difference between asynchronous program and synchronous program
is the ability to spawn multiple tasks and let them run in parallel.
This ability also brings the new challenge of how to manage tasks robustly,
as the control flow of programs become much more complex due to concurrent tasks.

The `moonbitlang/async` library adapts the *structured concurrency* paradigm
to solve the task management problem and improve robustness of async program.
In `moonbitlang/async`, spawning new task can only be done inside a *task group*,
while task groups can only be created via the `@async.with_task_group` function:

```moonbit
async fn[Result] with_task_group(
  f : async (@async.TaskGroup[Result]) -> Result,
) -> Result
```

The `with_task_group` function creates a new task group,
spawn a new task inside the task group,
and run `f` inside the new task with the group itself as argument.
`f` can then use the group to spawn more new tasks, using various methods such as `spawn_bg`:

```moonbit
/// Spawn a new task in the group and let it run in the background
fn[Result] @async.TaskGroup::spawn_bg(
  group : TaskGroup[Result],
  f : async () -> Unit,
  ...
) -> Unit
```

The magic of structured concurrency lies in the following rule for `with_task_group`:

> `with_task_group` will only return after all tasks inside the group has terminated

`with_task_group` will ensure the above property in all conditions.
Normaly, `with_task_group` will just wait for tasks to complete normally.
If `with_task_group` need to terminate immediately for some reasons, such as fatal error
(by default, `with_task_group` will fail immediately if any of its child task fails,
so that no error can be silently ignored),
it will cancel all child tasks properly, and wait for their cleanup operations to complete.
Altogether, the rule of `with_task_group` ensures that
*orphan tasks* (i.e. unused tasks that are still running because the program forget to cancel it)
can never exist in `moonbitlang/async`.

Here's a simple example of using `with_task_group` to create multiple tasks and let them run in parallel:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start with_task_group example
:end-before: end with_task_group example
```

`with_task_group` is a very powerful construct.
It can be used to simulate many async control flow operation.
For example, here's a function that run an async function with a timeout:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start custom with_timeout example
:end-before: end custom with_timeout example
```

The code itself is very simple, but the semantic of `with_task_group` ensures that this simple function will work properly in every corner case:

- if `f` return successfully before the timeout,
  since the sleep task is spawned with `no_wait=true`, `with_task_group` will not wait for the sleep task.
  To protect its rule, `with_task_group` will cancel the sleep task immediately.
  So `with_timeout(.., f)` will return immediately after `f` returns, without unnecessary delay.
- if `f` fails, the error will propagate to the whole `with_task_group`.
  The sleep task will again get cancelled automatically in this case.
- if `f` is still running when the timeout expires,
  the sleep task will raise a fatal timeout error, aborting the whole group.
  `f` will also get cancelled automatically in this case.

## Cancellation makes asynchronous program modular
In the previous section, "cancellation" has been mentioned multiple times.
Indeed, cancellation is a very important part in asynchronous programming.
In `moonbitlang/async`, every asynchronous operation is cancellable by default, including `with_task_group`.
So when you compose these basic asynchronous operations into bigger program,
no matter how complex your program is, it is automatically cancellable.

When a piece of asynchronous code is cancelled,
the cancellation signal is represented as an error raised at the point where the code previously blocked.
So there is no need to handle cancellation specially:
the cancellation signal will automically propagate through the program,
triggering cleanup operations in `defer` and error handlers.

The ability to cancel arbitrary async code makes async programs highly modular in MoonBit.
The `moonbitlang/async` package provides many useful combinators that perform
timeout limit, automatic retry, etc. for async program,
they all rely on the cancellation mechanism to work properly.
For example, the following program try to make a HTTP request with a timeout,
and allow at most three retry attempts:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async combinator example
:end-before: end async combinator example
```

## Interacting with the world
In addition to asynchronous programming primitives,
`moonbitlang/async` also provides an event loop for performing async IO operations,
as well as a rich set of IO operations,
including `http`/`https`, file IO, socket IO and process spawning,
with [decent performance](https://www.moonbitlang.com/blog/moonbit-async#performance-comparison).
You can find a complete list of supported operations and their documentation at [mooncakes.io](https://mooncakes.io/docs/moonbitlang/async),
and simple examples at [the GitHub repo](https://github.com/moonbitlang/async/tree/main/examples).
here's a quick taste of some of the most common features:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async IO example
:end-before: end async IO example
```

## JavaScript support
Although `moonbitlang/async` supports native backend best,
it also has basic support for JavaScript backend:

- all IO independent API, such as task group and timeout, are available
- IO related API are not available, because not all JavaScript environment (for example browsers) support them
- the `moonbitlang/async/js_async` provides support for integration with JavaScript promise,
  including waiting for an external JavaScript promise and exporting a MoonBit `async` function as a JavaScript promise.
  This allows interaction with native asynchronous operations of the JavaScript host.

See [the mooncakes.io page for `moonbitlang/async/js_async`](https://mooncakes.io/docs/moonbitlang/async/js_async) fore more details.
