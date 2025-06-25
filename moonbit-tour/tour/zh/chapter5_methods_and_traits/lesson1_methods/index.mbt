type MyInt Int derive(Show)

fn MyInt::increment(self : Self) -> Self {
  let MyInt(x) = self
  MyInt(x + 1)
}

fn main {
  let x = MyInt(39)
  let y = x.increment() // 用 `.` 语法调用方法
  let z = MyInt::increment(y) // 也可以用 `T::method_name` 调用
  println(z)
}
