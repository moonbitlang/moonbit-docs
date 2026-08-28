pub fn render(value : String) -> String {
  let builder = StringBuilder()
  builder <+ value
  builder.to_string()
}
