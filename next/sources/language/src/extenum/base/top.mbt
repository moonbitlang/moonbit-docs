// start extenum declare
pub extenum LogEvent[T]
// end extenum declare

// start extenum initial constructors
pub(all) extenum LogEvent[T] += {
  Info(T)
}
// end extenum initial constructors

// start extenum local extension
pub(all) extenum LogEvent[T] += {
  Warning(T)
  Critical(T, T)
}
// end extenum local extension
