# Async programming support

MoonBit adopts a coroutine based approach to async programming which is similar to [Kotlin](https://kotlinlang.org/docs/coroutines-overview.html).
The compiler support and concrete syntax is stable while the async library is still under development and considered experimental.

<!-- We highly appreciate any feedback or experiment with current design. -->

## Async function

Async functions are declared with the `async` keyword, and explicit [`raise` or `noraise`](error-handling.md#throwing-errors):

```moonbit
async fn my_async_function() -> Unit noraise {
  ...
}

///| anonymous/local function
test {
  let async_lambda = async fn() noraise { ... }
  async fn local_async_function() noraise {
    ...
  }


}
```

Since MoonBit is a statically typed language, the compiler will track its
asyncness, so you can just call async functions like normal functions, the
MoonBit IDE will highlight the async function call with a different style.

```moonbit

///|
async fn some_async_function() -> Unit raise {
  ...
}

///|
async fn another_async_function() -> Unit raise {
  some_async_function() // rendered in italic font
}
```

Async functions can only be called inside async functions.

#### WARNING
Currently, async functions
have not be supported in the body of `for .. in` loops yet, this
will be addressed in the future.

## Async primitives for suspension

MoonBit provides two core primitives for `%async.suspend` and `%async.run`:

```moonbit

///| `run_async` spawn a new coroutine and execute an async function in it
fn run_async(f : async () -> Unit noraise) -> Unit = "%async.run"

///| `suspend` will suspend the execution of the current coroutine.
/// The suspension will be handled by a callback passed to `suspend`
async fn[T, E : Error] suspend(
  // `f` is a callback for handling suspension
  f : (
    // the first parameter of `f` is used to resume the execution of the coroutine normally
    (T) -> Unit,
    // the second parameter of `f` is used to cancel the execution of the current coroutine
    // by throwing an error at suspension point
    (E) -> Unit,
  ) -> Unit,
) -> T raise E = "%async.suspend"
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

```moonbit

///|
suberror MyError derive(Show)

///|
async fn async_worker(
  logger~ : &Logger,
  throw_error~ : Bool,
) -> Unit raise MyError {
  suspend(fn(resume_ok, resume_err) {
    if throw_error {
      resume_err(MyError)
    } else {
      resume_ok(())
      logger.write_string("the end of the coroutine\n")
    }
  })
}

///|
test {
  // when supplying an anonymous function
  // to a higher order function that expects async parameter,
  // the `async` keyword can be omitted
  let logger = StringBuilder::new()
  fn local_test() {
    run_async(() => try {
      async_worker(logger~, throw_error=false)
      logger.write_string("the worker finishes\n")
    } catch {
      err => logger.write_string("caught: \{err}\n")
    })
    logger.write_string("after the first coroutine finishes\n")
    run_async(() => try {
      async_worker(logger~, throw_error=true)
      logger.write_string("the worker finishes\n")
    } catch {
      err => logger.write_string("caught: \{err}\n")
    })
  }

  local_test()
  inspect(
    logger,
    content=(
      #|the worker finishes
      #|the end of the coroutine
      #|after the first coroutine finishes
      #|caught: MyError
      #|
    ),
  )
}
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

```moonbit
#external
type JSTimer

///|
extern "js" fn js_set_timeout(f : () -> Unit, duration~ : Int) -> JSTimer =
  #| (f, duration) => setTimeout(f, duration)

///|
async fn sleep(duration : Int) -> Unit raise {
  suspend(fn(resume_ok, _resume_err) {
    js_set_timeout(duration~, fn() { resume_ok(()) }) |> ignore
  })
}

///|
test {
  run_async(fn() {
    try {
      sleep(500)
      println("timer 1 tick")
      sleep(1000)
      println("timer 1 tick")
      sleep(1500)
      println("timer 1 tick")
    } catch {
      _ => panic()
    }
  })
  run_async(fn() {
    try {
      sleep(600)
      println("timer 2 tick")
      sleep(600)
      println("timer 2 tick")
      sleep(600)
      println("timer 2 tick")
    } catch {
      _ => panic()
    }
  })
}
```

Integrating with JS Promise is easy too:
just pass `resume_ok` as the `resolve` callback and `resume_err` as the `reject` callback to a JS promise.
