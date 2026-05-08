// start extenum interaction
pub fn describe(event : @base.LogEvent[String]) -> String {
  match event {
    @base.Info(message) => "info: \{message}"
    @base.Warning(message) => "warning: \{message}"
    @base.Critical(code, message) => "critical \{code}: \{message}"
    @plugin.Debug(message) => "debug: \{message}"
    _ => "unknown"
  }
}

pub fn debug_event(message : String) -> @base.LogEvent[String] {
  @plugin.Debug(message)
}
// end extenum interaction

test "extenum interaction" {
  inspect(describe(@base.Info("started")), content="info: started")
  inspect(describe(@base.Warning("retrying")), content="warning: retrying")
  inspect(
    describe(@base.Critical("E_CONN", "database unavailable")),
    content="critical E_CONN: database unavailable",
  )
  inspect(describe(debug_event("verbose trace")), content="debug: verbose trace")
}
