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
  T::f(Handler::{ run: x => ignore(x) })
}
