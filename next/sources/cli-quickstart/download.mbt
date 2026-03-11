///|
/// start run
pub async fn run(config : Config) -> Unit {
  let (response, body) = @http.get_stream(config.url)
  defer body.close()

  guard response.code is (200..<300) else {
    fail("download failed: \{response.code} \{response.reason}")
  }

  match config.output {
    Some(path) => {
      let file = @fs.create(path, permission=0o644)
      defer file.close()
      file.write_reader(body)
      @stdio.stderr.write("saved \{config.url} to \{path}\n")
    }
    None => @stdio.stdout.write_reader(body)
  }
}
// end run
