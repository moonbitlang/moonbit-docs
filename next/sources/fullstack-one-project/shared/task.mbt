///|
/// start shared-model
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
/// end shared-model
