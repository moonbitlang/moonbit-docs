///|
/// start async function declaration
async fn my_async_function() -> String {
  let (response, body) = @http.get("https://www.moonbitlang.com")
  guard response.code is (200..<300) else {
    fail("server responded with \{response.code} \{response.reason}")
  }
  body.text()
}
// end async function declaration

// start optional arguments async

///|
async fn fetch_default() -> Int {
  ...
}

///|
async fn build(x? : Int = fetch_default()) -> Int {
  ...
}

///|
async fn use_value() -> Int {
  build(x=fetch_default())
}
// end optional arguments async

///|
// start with_task_group example
async test "with_task_group" {
  let log = []
  @async.with_task_group(group => {
    group.spawn_bg(() => for _ in 0..<3 {
      log.push("task #1 tick")
      @async.sleep(200) // sleep for 200ms
    })
    group.spawn_bg(() => {
      @async.sleep(100)
      for _ in 0..<3 {
        log.push("task #2 tick")
        @async.sleep(200)
      }
    })
  })
  json_inspect(log, content=[
    "task #1 tick", "task #2 tick", "task #1 tick", "task #2 tick", "task #1 tick",
    "task #2 tick",
  ])
}
// end with_task_group example

///|
// start custom with_timeout example
async fn with_timeout(timeout : Int, f : async () -> Unit) -> Unit {
  @async.with_task_group(group => {
    group.spawn_bg(no_wait=true, () => {
      @async.sleep(timeout)
      raise Failure::Failure("timeout!")
    })
    f()
  })
}
// end custom with_timeout example

///|
// start async combinator example
async fn make_request() -> String {
  @async.retry(Immediate, max_retry=3, () => @async.with_timeout(1000, () => {
    let (response, body) = @http.get("https://www.moonbitlang.com")
    guard response.code is (200..<300) else {
      fail("the HTTP request is not successful")
    }
    body.text()
  }))
}
// end async combinator example

///|
// start async IO example
async fn download_file(url : String, file_name : String) -> Unit {
  // perform the transfer lazily to save memory
  let (_response, body) = @http.get_stream(url)
  defer body.close()
  let out_file = @fs.create(file_name, permission=0o644)
  defer out_file.close()
  out_file.write_reader(body)
}
// end async IO example
