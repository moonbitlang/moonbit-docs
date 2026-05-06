///|
type Store

///|
#must_implement_one(load, save)
pub(open) trait Persist {
  load(Self) -> String = _
  save(Self, String) -> Unit = _
  reset(Self) -> Unit = _
}

///|
impl Persist with load(_) {
  "cached"
}

///|
impl Persist with save(_, _) {

}

///|
impl Persist with reset(_) {

}

///|
pub impl Persist for Store with load(_) {
  "local"
}
