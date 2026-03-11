///|
/// start main
async fn main {
  let config = @app.parse_config(@env.args())
  @app.run(config)
}
// end main
