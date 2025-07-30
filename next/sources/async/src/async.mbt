///| start async function declaration
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
// end async function declaration

// start async function call syntax

///|
async fn some_async_function() -> Unit raise {
  ...
}

///|
async fn another_async_function() -> Unit raise {
  some_async_function() // rendered in italic font
}
// end async function call syntax

// start async primitive

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
// end async primitive

// start async example

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
// end async example

///| start async timer example
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
// end async timer example
