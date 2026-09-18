///|
pub(all) enum Status {
  Ready
  Busy
}

///|
pub fn describe(status : Status) -> String {
  match status {
    Ready => "ready"
    Busy => "busy"
    Status::.. => "unknown"
  }
}
