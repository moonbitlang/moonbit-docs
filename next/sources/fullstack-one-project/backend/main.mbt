///|
let html_headers : Map[String, String] = {
  "Content-Type": "text/html; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
}

///|
let js_headers : Map[String, String] = {
  "Content-Type": "text/javascript; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
}

///|
let json_headers : Map[String, String] = {
  "Content-Type": "application/json; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
}

///|
let text_headers : Map[String, String] = {
  "Content-Type": "text/plain; charset=utf-8",
  "Access-Control-Allow-Origin": "*",
}

///|
let index_html_path = "backend/index.html"

///|
let frontend_js_path = "_build/js/debug/build/frontend/frontend.js"

///|
async fn send_file(
  conn : @http.ServerConnection,
  file_path : String,
  headers : Map[String, String],
  missing_message : String,
) -> Unit {
  if @fs.exists(file_path) {
    let file = @fs.open(file_path, mode=ReadOnly)
    defer file.close()
    conn
    ..send_response(200, "OK", extra_headers=headers)
    ..write_reader(file)
    .end_response()
  } else {
    conn
    ..send_response(404, "NotFound", extra_headers=text_headers)
    ..write(missing_message)
    .end_response()
  }
}

///|
/// start backend-main
async fn main {
  @stdio.stdout.write("starting backend on http://127.0.0.1:8080\n")
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:8080")) catch {
    err => {
      @stdio.stdout.write("failed to start backend: \{err}\n")
      return
    }
  }

  server.run_forever((request, body, conn) => {
    match (request.meth, request.path) {
      (Get, "/") =>
        send_file(
          conn, index_html_path, html_headers, "missing backend/index.html",
        )
      (Get, "/frontend.js") =>
        send_file(
          conn, frontend_js_path, js_headers, "missing frontend bundle; run `moon build frontend --target js`",
        )
      (Post, "/submit") => {
        let raw_body = body.read_all().text() catch { _ => "" }
        let response : @shared.SubmitTitleResponse = try {
          let request : @shared.SubmitTitleRequest = @json.from_json(
            @json.parse(raw_body),
          )
          try {
            @shared.validate_request(request)
            @shared.SubmitTitleResponse::Accepted(
              request.title.trim().to_owned(),
            )
          } catch {
            err => @shared.SubmitTitleResponse::ValidationError(err)
          }
        } catch {
          _ => @shared.SubmitTitleResponse::InvalidJson
        }
        let code = match response {
          @shared.SubmitTitleResponse::Accepted(_) => 200
          _ => 400
        }
        let reason = if code == 200 { "OK" } else { "BadRequest" }
        conn
        ..send_response(code, reason, extra_headers=json_headers)
        ..write(response.to_json().stringify())
        .end_response()
      }
      _ =>
        conn
        ..send_response(404, "NotFound", extra_headers=text_headers)
        ..write("Not Found")
        .end_response()
    }
  })
}
/// end backend-main
