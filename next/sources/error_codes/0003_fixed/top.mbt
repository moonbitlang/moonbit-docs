// make public

///|
pub struct Foo {
  bar : Int32
}
// end make public

///| eliminate 0009
fn init {
  let _ = Foo::{ bar: 10 }

}
