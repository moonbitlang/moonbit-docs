// start extenum declare
pub(all) extenum LogEvent[T] {
  Info(T)
}
// end extenum declare

// start extenum local extension
pub(all) extenum LogEvent[T] += {
  Warning(T)
  Critical(T, T)
}
// end extenum local extension
