///|
/// start shared-model
pub(all) struct SubmitTitleRequest {
  title : String
} derive(Eq, ToJson, FromJson)

///|
pub extend SubmitTitleRequest with Eq::{not_equal, equal}

///|
pub extend SubmitTitleRequest with ToJson::{to_json}

///|
pub extend SubmitTitleRequest with @moonbitlang/core/json.FromJson::{from_json}

///|
pub(all) suberror TitleValidationError {
  EmptyTitle
  TooLong(Int)
  ForbiddenHash
} derive(Eq, ToJson, FromJson)

///|
pub extend TitleValidationError with Eq::{not_equal, equal}

///|
pub extend TitleValidationError with ToJson::{to_json}

///|
pub extend TitleValidationError with @moonbitlang/core/json.FromJson::{from_json}

///|
pub(all) enum SubmitTitleResponse {
  Accepted(String)
  ValidationError(TitleValidationError)
  InvalidJson
} derive(Eq, ToJson, FromJson)

///|
pub extend SubmitTitleResponse with Eq::{not_equal, equal}

///|
pub extend SubmitTitleResponse with ToJson::{to_json}

///|
pub extend SubmitTitleResponse with @moonbitlang/core/json.FromJson::{from_json}

///|
pub fn validate_request(
  request : SubmitTitleRequest,
) -> Unit raise TitleValidationError {
  let title = request.title.trim().to_owned()
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

///|
pub extend SubmitTitleResponse with Show::{to_string, output}
/// end shared-model
