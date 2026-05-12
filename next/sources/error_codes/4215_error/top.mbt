pub(all) type Writer

pub fn Writer::write_string(self : Writer, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

pub fn render(writer : Writer) -> Unit {
  writer <+ 1
  //     ^^
  // Error: Expected a template string here.
}
