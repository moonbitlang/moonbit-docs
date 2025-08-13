struct MyStruct {
  field: Int
}

typealias StructAlias = MyStruct derive(Show) // Error: `derive` is not allowed for type alias