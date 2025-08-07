// make public

///|
pub struct Foo {
  bar : Int
}
// end make public

///| eliminate 0009
fn init {
  let _ = Foo::{ bar: 10 }

}
