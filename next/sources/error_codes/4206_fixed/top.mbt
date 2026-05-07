///|
type Token

///|
#must_implement_one(render)
pub(open) trait Render {
  render(Self) -> String = _
  debug(Self) -> String = _
}

///|
impl Render with render(_) {
  "rendered"
}

///|
impl Render with debug(_) {
  "debug"
}

///|
pub impl Render for Token with render(_) {
  "token"
}
