pub(open) trait T {
  f(Self) -> Unit
}

pub struct Handler {
  run : (Int) -> Unit
}

impl T for Handler with f(self) {
  (self.run)(0)
}

fn init {
  Handler::{ run: x => ignore(x) }.f()
}
