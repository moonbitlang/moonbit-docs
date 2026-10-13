///|
using @html {button, div, h2, input, p}

///|
fn local_warning(title : String) -> String? {
  let request = @shared.SubmitTitleRequest::{ title, }
  try {
    @shared.validate_request(request)
    None
  } catch {
    err => Some(@shared.warning_text(err))
  }
}

///|
struct Model {
  title : String
  warning : String?
  server_message : String?
} derive(Eq)

///|
enum Msg {
  Edit(String)
  Submit
  ServerReplied(Result[String, String])
}

///|
/// start frontend-main
fn main {
  let app = @rabbita.elmish(
    model={ title: "", warning: None, server_message: None },
    update=(model, msg, dispatch) => {
      match msg {
        Edit(title) => {
          let warning = local_warning(title)
          ({ title, warning, server_message: None }, @rabbita.none)
        }
        Submit =>
          match model.warning {
            Some(message) =>
              (
                { ..model, server_message: Some("not sent: \{message}") },
                @rabbita.none,
              )
            None => {
              let request = @shared.SubmitTitleRequest::{ title: model.title }
              let request_json = request.to_json().stringify()
              let cmd = @rhttp.post("http://127.0.0.1:8080/submit")
                .with_text(request_json)
                .expect_text(result => dispatch(ServerReplied(
                  result.map_err(err => err.to_string()),
                )))
              (
                { ..model, server_message: Some("sending json request...") },
                cmd,
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
          ({ ..model, server_message, }, @rabbita.none)
        }
      }
    },
    view=(model, dispatch) => {
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
        ),
        button(on_click=dispatch(Submit), "Submit as JSON"),
        warning_line,
        server_line,
      ])
    },
  )
  app.mount("app")
}
/// end frontend-main
