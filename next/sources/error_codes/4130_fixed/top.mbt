pub struct MyStruct {
  field : Int
} derive(Debug)

pub extend MyStruct with Debug::{to_repr}

pub type StructAlias = MyStruct

pub fn make_alias() -> StructAlias {
  { field: 1 }
}
