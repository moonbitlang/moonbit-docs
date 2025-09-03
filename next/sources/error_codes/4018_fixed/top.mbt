///|
trait HasDefault {
  f(Self) -> Unit = _
}

///|
impl HasDefault with f(_) {

}

///|
struct S(Int)

///|
test {
  let s : S = S(3)
  let _ = Show::to_string(s)
  HasDefault::f(s)
}
