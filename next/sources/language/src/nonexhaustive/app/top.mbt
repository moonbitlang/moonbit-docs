// start non exhaustive match
///|
pub fn render(response : @base.Response) -> String {
  match response {
    @base.Ok(body) => body
    @base.NotFound => "not found"
    @base.Response::.. => "unsupported response"
  }
}
// end non exhaustive match

///|
test "match a non-exhaustive enum" {
  inspect(render(@base.Ok("hello")), content="hello")
  inspect(render(@base.NotFound), content="not found")
}
