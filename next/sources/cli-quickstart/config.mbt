///|
/// start config
pub struct Config {
  url : String
  output : String?
} derive(Eq)

///|
pub fn command() -> @argparse.Command {
  @argparse.Command(
    "moon-fetch",
    about="Download a URL to stdout or a file",
    options=[
      @argparse.OptionArg(
        "output",
        short='o',
        about="Write the response body to this file",
      ),
    ],
    positionals=[
      @argparse.PositionArg(
        "url",
        about="HTTP or HTTPS URL to download",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
}

///|
pub fn parse_config(argv : ArrayView[String]) -> Config raise {
  let matches = @argparse.parse(command(), argv~)
  let values : Map[String, Array[String]] = matches.values
  guard values is { "url": [url], "output"? : output_paths, .. } else {
    fail("missing url")
  }
  let output = match output_paths {
    Some([output, ..]) => Some(output)
    _ => None
  }
  { url, output }
}
// end config
