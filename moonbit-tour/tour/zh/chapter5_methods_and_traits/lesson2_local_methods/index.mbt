///|
/// 使用本地方法 `add_range` 扩展 `@sorted_set.SortedSet` 类型。
///
/// `SortedSet` 定义在 `moonbitlang/core/sorted_set`，你可以在
/// https://mooncakes.io/docs/moonbitlang/core/sorted_set 查看 API 文档。
fn @sorted_set.SortedSet::add_range(self : Self[Int], l : Int, r : Int) -> Unit {
  for i in l..=r {
    self.add(i)
  }
}

///|
fn main {
  let set = @sorted_set.new()
  set.add_range(1, 10)
  set.add_range(15, 20)
  println(set)
}
