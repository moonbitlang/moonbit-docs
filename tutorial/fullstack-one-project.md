# Fullstack in One MoonBit Project

This tutorial builds a small fullstack app in one MoonBit module.

You will implement one shared validation rule set and use it in both places:

- `frontend/`: show local warnings and call backend
- `backend/`: validate again and return JSON response

The key is `supported-targets`:

- `frontend/` is `js`
- `backend/` is `native`
- `shared/` is target-agnostic

## Prerequisites

- MoonBit toolchain installed
- `hurl` installed for API testing

## Step 1: Create the module

```bash
moon new fullstack_one_project
cd fullstack_one_project
moon add moonbitlang/async@0.17.0
moon add moonbit-community/rabbita
```

Project layout:

```text
fullstack_one_project
├── Makefile
├── moon.mod.json
├── backend
│   ├── api.hurl
│   ├── index.html
│   ├── main.mbt
│   └── moon.pkg
├── frontend
│   ├── main.mbt
│   └── moon.pkg
└── shared
    ├── moon.pkg
    ├── shared_test.mbt
    └── task.mbt
```

Module config:

```json
{
  "name": "moonbit-community/fullstack-one-project-doc",
  "version": "0.1.0",
  "deps": {
    "moonbitlang/async": "0.17.0",
    "moonbit-community/rabbita": "0.11.5"
  },
  "preferred-target": "native",
  "supported-targets": "+wasm+wasm-gc+js+native"
}
```

## Step 2: Implement shared domain validation

Define request/response types with `derive(ToJson, FromJson)` and one `suberror`-based validator in `shared/`.
Both frontend and backend import this package.

```moonbit
import {
  "moonbitlang/core/json" @json,
}
```

```moonbit
pub(all) struct SubmitTitleRequest {
  title : String
} derive(Eq, ToJson, FromJson)

///|
pub(all) suberror TitleValidationError {
  EmptyTitle
  TooLong(Int)
  ForbiddenHash
} derive(Eq, ToJson, FromJson)

///|
pub(all) enum SubmitTitleResponse {
  Accepted(String)
  ValidationError(TitleValidationError)
  InvalidJson
} derive(Eq, ToJson, FromJson)

///|
pub fn validate_request(
  request : SubmitTitleRequest,
) -> Unit raise TitleValidationError {
  let title = request.title.trim().to_string()
  if title.length() == 0 {
    raise EmptyTitle
  } else if title.length() > 24 {
    raise TooLong(title.length())
  } else if title.rev_find("#") is Some(_) {
    raise ForbiddenHash
  }
}

///|
pub fn warning_text(err : TitleValidationError) -> String {
  match err {
    EmptyTitle => "title cannot be empty"
    TooLong(length) => "title is too long (\{length}), max is 24"
    ForbiddenHash => "title cannot contain '#'"
  }
}

///|
pub impl Show for SubmitTitleResponse with output(self, logger) {
  let text = match self {
    Accepted(title) => "accepted: \{title}"
    ValidationError(err) => "validation_error: \{warning_text(err)}"
    InvalidJson => "invalid_json: invalid request json"
  }
  logger.write_string(text)
}
```

## Step 3: Implement the frontend (`js`)

Frontend behavior:

- validate title locally with shared rules
- if valid, `POST` to backend `/submit`
- display backend response text

```moonbit
import {
  "moonbit-community/fullstack-one-project-doc/shared" @shared,
  "moonbitlang/core/json" @json,
  "moonbit-community/rabbita" @rabbita,
  "moonbit-community/rabbita/html" @html,
  "moonbit-community/rabbita/http" @rhttp,
}

supported_targets = "js"

options(
  "is-main": true,
)
```

```moonbit
fn main {
  let app = @rabbita.cell(
    model={ title: "", warning: None, server_message: None },
    update=(dispatch, msg, model) => {
      match msg {
        Edit(title) => {
          let warning = local_warning(title)
          (@rabbita.none, { title, warning, server_message: None })
        }
        Submit =>
          match model.warning {
            Some(message) =>
              (
                @rabbita.none,
                { ..model, server_message: Some("not sent: \{message}") },
              )
            None => {
              let request = @shared.SubmitTitleRequest::{ title: model.title }
              let request_json = request.to_json().stringify()
              let expect : @rhttp.Expecting[@rabbita.Cmd, Unit] = @rhttp.Expecting::Text(result => {
                  dispatch(ServerReplied(result))
                },
              )
              let cmd = @rhttp.post(
                "http://127.0.0.1:8080/submit",
                @rhttp.Body::Text(request_json),
                expect~,
              )
              (
                cmd,
                { ..model, server_message: Some("sending json request...") },
              )
            }
          }
        ServerReplied(result) => {
          let server_message = match result {
            Ok(raw_json) =>
              try {
                let response : @shared.SubmitTitleResponse = @json.from_json(
                  @json.parse(raw_json),
                )
                Some("\{response}")
              } catch {
                _ => Some("invalid backend response json")
              }
            Err(err) => Some("request failed: \{err}")
          }
          (@rabbita.none, { ..model, server_message, })
        }
      }
    },
    view=(dispatch, model) => {
      let warning_line = match model.warning {
        Some(message) => p("warning: \{message}")
        None => p("local validation passed")
      }
      let server_line = match model.server_message {
        Some(response) => p("backend response: \{response}")
        None => p("backend response: (none yet)")
      }
      let value = model.title
      div([
        h2("Shared Validation Demo"),
        input(
          input_type=Text,
          value~,
          on_input=text => dispatch(Edit(text)),
          nothing,
        ),
        button(on_click=dispatch(Submit), "Submit as JSON"),
        warning_line,
        server_line,
      ])
    },
  )
  @rabbita.new(app).mount("app")
}
```

## Step 4: Implement the backend (`native`)

Backend behavior:

- serve `GET /` from static `backend/index.html`
- serve `GET /frontend.js` from frontend build output
- handle `POST /submit` with shared validation and JSON response

```moonbit
import {
  "moonbit-community/fullstack-one-project-doc/shared" @shared,
  "moonbitlang/core/json" @json,
  "moonbitlang/async",
  "moonbitlang/async/fs" @fs,
  "moonbitlang/async/http" @http,
  "moonbitlang/async/socket" @socket,
  "moonbitlang/async/stdio",
}

supported_targets = "native"

options(
  "is-main": true,
)
```

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Shared Validation Demo</title>
  </head>
  <body>
    <h1>Shared Validation Demo</h1>
    <p>Backend serves this page and the built frontend bundle.</p>
    <div id="app"></div>
    <script src="/frontend.js"></script>
  </body>
</html>
```

```moonbit
async fn main {
  @stdio.stdout.write("starting backend on http://127.0.0.1:8080\n")
  let server = @http.Server::new(@socket.Addr::parse("127.0.0.1:8080")) catch {
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
              request.title.trim().to_string(),
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
```

## Step 5: Use Makefile shortcuts

```makefile
.PHONY: help build-frontend run-backend check test api-test verify verify-all clean

help:
	@echo "Targets:"
	@echo "  make build-frontend  Build frontend JS bundle"
	@echo "  make run-backend     Run backend server on 127.0.0.1:8080"
	@echo "  make check           Run moon check for all targets"
	@echo "  make test            Run moon test for all targets"
	@echo "  make api-test        Run Hurl API tests against local backend"
	@echo "  make verify          Run check + test"
	@echo "  make verify-all      Run verify + api-test"
	@echo "  make clean           Remove build artifacts"

build-frontend:
	moon build frontend --target js

run-backend:
	moon run backend --target native

check:
	moon check --deny-warn --target all

test:
	moon test --deny-warn --target all

api-test: build-frontend
	@command -v hurl >/dev/null 2>&1 || { echo "hurl is required for api-test"; exit 1; }
	@set -eu; \
		moon run backend --target native >/tmp/fullstack-one-project-backend.log 2>&1 & \
		pid=$$!; \
		trap 'kill $$pid >/dev/null 2>&1 || true' EXIT INT TERM; \
		sleep 1; \
		hurl --test backend/api.hurl

verify: check test

verify-all: verify api-test

clean:
	rm -rf _build
```

Common workflow:

```bash
make build-frontend
make run-backend
```

Then open `http://127.0.0.1:8080/` in a browser.

## Step 6: Test API with Hurl

Hurl test suite:

```hurl
GET http://127.0.0.1:8080/
HTTP 200
[Asserts]
body contains "<div id=\"app\"></div>"

GET http://127.0.0.1:8080/frontend.js
HTTP 200
[Asserts]
body contains "function"

POST http://127.0.0.1:8080/submit
Content-Type: application/json
{
  "title": "Write docs"
}
HTTP 200
[Asserts]
jsonpath "$[0]" == "Accepted"
jsonpath "$[1]" == "Write docs"

POST http://127.0.0.1:8080/submit
Content-Type: application/json
{
  "title": "bad #title"
}
HTTP 400
[Asserts]
jsonpath "$[0]" == "ValidationError"
jsonpath "$[1]" == "ForbiddenHash"

POST http://127.0.0.1:8080/submit
Content-Type: application/json
{
  "title": "01234567890123456789012345"
}
HTTP 400
[Asserts]
jsonpath "$[0]" == "ValidationError"
jsonpath "$[1][0]" == "TooLong"
jsonpath "$[1][1]" == 26

POST http://127.0.0.1:8080/submit
Content-Type: application/json
```
{"title":
```
HTTP 400
[Asserts]
jsonpath "$" == "InvalidJson"
```

Run it:

```bash
make api-test
```

This verifies:

- static `GET /` and `GET /frontend.js`
- accepted submit (`200`)
- rejected submit (`400`) for invalid titles
- rejected submit (`400`) for malformed JSON input

## Step 7: Verify everything

```bash
make verify-all
```

This runs:

- `moon check --deny-warn --target all`
- `moon test --deny-warn --target all`
- Hurl API tests

You now have one executable project where frontend and backend share the same validation contract and error model.
