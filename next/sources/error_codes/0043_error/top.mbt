///|
/// This is an invalid usage as the deprecation warning should be unique
#deprecated("")
#deprecated("The attribute is unused because it's duplicated")
pub fn f() -> Unit {

}

///|
/// This is an invalid usage as struct can't be external
#external
pub struct T {}

///|
/// This is an invalid usage as it expects a string
#deprecated(asdfasdf)
pub fn g() -> Unit {

}
