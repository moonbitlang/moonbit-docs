///|
/// start config
pub struct Config {
  url : String
  output : String?
} derive(Show, Eq)

///|
pub fn command() -> @argparse.Command {
  @argparse.Command::new(
    "moon-fetch",
    about="Download a URL to stdout or a file",
    options=[
      @argparse.OptionArg::new(
        "output",
        short='o',
        about="Write the response body to this file",
      ),
    ],
    positionals=[
      @argparse.PositionArg::new("url", about="HTTP or HTTPS URL to download"),
    ],
  )
}

///|
pub fn parse_config(argv : Array[String]) -> Config raise {
  let matches = @argparse.parse(command(), argv~)
  let values : Map[String, Array[String]] = matches.values
  guard values is { "url": [url, ..], "output"? : output_paths, .. } else {
    fail("missing url")
  }
  let output = match output_paths {
    Some([output, ..]) => Some(output)
    _ => None
  }
  { url, output }
}
// end config
