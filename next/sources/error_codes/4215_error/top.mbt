pub fn render(value : String) -> String {
  let builder = StringBuilder::new()
  builder <+ value
  builder.to_string()
}
