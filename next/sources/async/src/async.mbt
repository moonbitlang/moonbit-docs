// start async function declaration
async fn my_async_function() -> Unit {
  ...
}

// anonymous/local function
test {
  let async_lambda = async fn () {
    ...
  }
  async fn local_async_function() {
    ...
  }
}
// end async function declaration

// start async function call syntax
async fn some_async_function() -> Unit! {
  ...
}

async fn another_async_function() -> Unit! {
  // error will be rethrowed by `!!`
  some_async_function!!()
}
// end async function call syntax

// start async primitive

// `run_async` spawn a new coroutine and execute an async function in it
fn run_async(f : async () -> Unit) -> Unit = "%async.run"

// `suspend` will suspend the execution of the current coroutine.
// The suspension will be handled by a callback passed to `suspend`
async fn suspend[T, E : Error](
  // `f` is a callback for handling suspension
  f : (
    // the first parameter of `f` is used to resume the execution of the coroutine normally
    (T) -> Unit,
    // the second parameter of `f` is used to cancel the execution of the current coroutine
    // by throwing an error at suspension point
    (E) -> Unit
  ) -> Unit
) -> T!E = "%async.suspend"
// end async primitive

// start async example
type! MyError derive(Show)

async fn async_worker(throw_error~ : Bool) -> Unit!MyError {
  suspend!!(fn (resume_ok, resume_err) {
    if throw_error {
      resume_err(MyError)
    } else {
      resume_ok(())
      println("the end of the coroutine")
    }
  })
}

// the program below should print:
//
//   the worker finishes
//   the end of the coroutine
//   after the first coroutine finishes
//   caught MyError
test {
  // when supplying an anonymous function
  // to a higher order function that expects async parameter,
  // the `async` keyword can be omitted
  run_async(fn () {
    try {
      async_worker!!(throw_error=false)
      println("the worker finishes")
    } catch {
      err => println("caught: \{err}")
    }
  })
  println("after the first coroutine finishes")
  run_async(fn () {
    try {
      async_worker!!(throw_error=true)
      println("the worker finishes")
    } catch {
      err => println("caught: \{err}")
    }
  })
}
// end async example

// start async timer example
extern type JSTimer
extern "js" fn js_set_timeout(f : () -> Unit, duration : Int) -> JSTimer =
  #| (f, duration) => setTimeout(f, duration)

async fn sleep(duration : Int) -> Unit! {
  suspend!!(fn (resume_ok, _resume_err) {
    let _ = js_set_timeout(fn () { resume_ok(()) }, duration)
  })
}

test {
  run_async(fn () {
    try {
      sleep!!(500)
      println("timer 1 tick")
      sleep!!(1000)
      println("timer 1 tick")
      sleep!!(1500)
      println("timer 1 tick")
    } catch { _ => panic() }
  })
  run_async(fn () {
    try {
      sleep!!(600)
      println("timer 2 tick")
      sleep!!(600)
      println("timer 2 tick")
      sleep!!(600)
      println("timer 2 tick")
    } catch { _ => panic() }
  })
}
// end async timer example
