pub struct StructWrapper(MyStruct)

pub fn wrap(value : MyStruct) -> StructWrapper {
  StructWrapper(value)
}
