pub extenum Event

pub(all) extenum Event += {
  Started
}

pub extenum Event += {
  Stopped
}

pub fn all() -> (Event, Event) {
  (Started, Stopped)
}
