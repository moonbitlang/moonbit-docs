pub struct MyStruct {
  field : Int
} derive(Debug)

pub type StructAlias = MyStruct

pub fn make_alias() -> StructAlias {
  { field: 1 }
}
