type MyInt Int

fn increment(self : MyInt) -> MyInt {
  MyInt(self._ + 1)
}

fn MyInt::println(x : MyInt) -> Unit {
  println("MyInt(\{x._})")
}

fn main {
  let x = MyInt(39)
  let y = x.increment() // 用 `.` 语法调用方法
  let z = increment(y) // `fn increment(..)` 可以直接调用
  let w = MyInt::increment(z) // 也可以用 `T::method_name` 调用
  w.println()
  MyInt::println(w) // `fn MyInt::println` 不能直接用 `println(..)` 调用
}
