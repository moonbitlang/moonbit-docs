# Async programming support

MoonBit adopts a coroutine based approach to async programming which is similar to [Kotlin](https://kotlinlang.org/docs/coroutines-overview.html).
Asynchronous programming in MoonBit consists of two parts: compiler support for `async` functions, and the official async runtime `moonbitlang/core/async`.
Currently, `moonbitlang/core/async` supports the native backend best, has limited
support for the JavaScript backend, and provides experimental Wasm1 support.
The API of `moonbitlang/core/async` is not considered stable, and may change in the future.

<!-- We highly appreciate any feedback or experiment with current design. -->

Use the standard library's `moonbitlang/core/async` packages for new async code.
These packages are experimental. To suppress experimental-package warnings,
add `options("allow-experimental-packages": true)` to the importing package's
`moon.pkg`.

## Getting started
`moonbitlang/core/async` ships with the toolchain; no `moon add` command or
extra module dependency is needed. Set `preferred_target = "native"` in
`moon.mod` for native IO examples, then import the packages you use in `moon.pkg`:

```{literalinclude} /sources/async/src/moon.pkg
:language: moonbit
:start-after: start async imports
:end-before: end async imports
```

If you want a workflow-first example, see the [Native CLI Quickstart](/tutorial/cli-quickstart.md).

The list of packages in `moonbitlang/core/async` and their detailed documentation
can be found on [mooncakes.io](https://mooncakes.io/docs/moonbitlang/core/async).
This article introduces the basic concepts and some of the most important APIs.

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

Async functions can only be called inside async functions.
Calling `async` function will result in the caller being blocked
and waiting for the callee to return, similar to `await` in many other languages.

MoonBit has first-class support for asynchronous programming.
You can use `async fn main` to declare an asynchronous program entry,
or use `async test` to write test for asynchronous code.
Asynchronous tests are automatically run in parallel by default.
Notice that you must import `moonbitlang/core/async` in your package to use `async fn main` and `async test`.

Async functions are cancellable by default. Add `nocancel` to promise that a
function does not introduce cancellation. A `nocancel` async function may call
synchronous functions and other `nocancel` async functions, but it cannot call
a cancellable async function. This effect is independent of ordinary errors:
`noraise` rules out ordinary errors, while `noraise + nocancel` rules out both
ordinary errors and cancellation.

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start nocancel function
:end-before: end nocancel function
```

## Structured concurrency and task group
If an asynchronous program only call async function directly (i.e. `await`),
then the control flow of the program is linear,
and the program is no different from a normal, synchronous programming.
The fundamental difference between asynchronous program and synchronous program
is the ability to spawn multiple tasks and let them run in parallel.
This ability also brings the new challenge of how to manage tasks robustly,
as the control flow of programs become much more complex due to concurrent tasks.

The `moonbitlang/core/async` library adapts the *structured concurrency* paradigm
to solve the task management problem and improve robustness of async program.
In `moonbitlang/core/async`, spawning new task can only be done inside a *task group*,
while task groups can only be created via the `@async.with_task_group` function:

```moonbit
async fn with_task_group(
  f : async (@async.TaskGroup) -> Unit,
) -> Unit
```

The `with_task_group` function creates a new task group,
spawn a new task inside the task group,
and run `f` inside the new task with the group itself as argument.
`f` can then use the group to spawn more new tasks, using various methods such as `spawn_bg`:

```moonbit
/// Spawn a new task in the group and let it run in the background
fn @async.TaskGroup::spawn_bg(
  group : @async.TaskGroup,
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
can never exist in `moonbitlang/core/async`.

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
In `moonbitlang/core/async`, every asynchronous operation is cancellable by default, including `with_task_group`.
So when you compose these basic asynchronous operations into bigger program,
no matter how complex your program is, it is automatically cancellable.

When a piece of asynchronous code is cancelled, the cancellation signal is
raised at the point where the code previously blocked. Ordinary `catch`
handlers do not intercept this signal. It propagates automatically through the
program, while cleanup registered with `defer` or `errdefer` still runs.

Running a cleanup block does not make its asynchronous operations immune to
cancellation. Cancellable operations inside it can be cancelled immediately.
Protect required asynchronous cleanup from cancellation; see
[E0098](/language/error_codes/E0098.md) for an example using the core runtime.

The ability to cancel arbitrary async code makes async programs highly modular in MoonBit.
The `moonbitlang/core/async` package provides many useful combinators that perform
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
`moonbitlang/core/async` also provides an event loop for performing async IO operations,
as well as a rich set of IO operations,
including `http`/`https`, file IO, socket IO and process spawning,
with [decent performance](https://www.moonbitlang.com/blog/moonbit-async#performance-comparison).
You can find a complete list of supported operations and their documentation at [mooncakes.io](https://mooncakes.io/docs/moonbitlang/core/async).
Here is an example that streams an HTTP response into a file:

```{literalinclude} /sources/async/src/async.mbt
:language: moonbit
:start-after: start async IO example
:end-before: end async IO example
```

## JavaScript support
Although `moonbitlang/core/async` supports native backend best,
it also has basic support for JavaScript backend:

- all IO independent API, such as task group and timeout, are available
- IO related API are not available, because not all JavaScript environment (for example browsers) support them
- the `moonbitlang/core/async/js_async` provides support for integration with JavaScript promise,
  including waiting for an external JavaScript promise and exporting a MoonBit `async` function as a JavaScript promise.
  This allows interaction with native asynchronous operations of the JavaScript host.

See [the mooncakes.io page for `moonbitlang/core/async/js_async`](https://mooncakes.io/docs/moonbitlang/core/async/js_async) for more details.

## Experimental Wasm1 support

The core async packages provide experimental Wasm1 support. Programs using
async IO on this backend currently need the latest `moonrun`; they are not
portable to other WebAssembly runtimes.
