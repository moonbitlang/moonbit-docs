///|
pub(open) trait Foo {
  foo(Self) -> Unit = _
}

///|
impl Foo with foo(_) {

}

///|
test {
  let x : Int = 0
  Foo::foo(x)
}
