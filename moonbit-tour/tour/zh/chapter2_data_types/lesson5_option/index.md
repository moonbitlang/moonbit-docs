# Option

`Option[Char]` 是一个表示可能存在也可能不存在的 `Char` 值的枚举。这是一种处理异常情况的常见方式。

- `None` 表示值缺失。
- `Some(e)` 是一个包含值 `e` 的包装器。

类型中的 `[Char]` 部分是一个类型参数，这意味着 `Option` 中的值类型是 `Char`。我们可以使用 `Option[String]`、`Option[Double]` 等。我们将在后面介绍泛型。

类型注释 `Option[A]` 可以简写为 `A?`。

你可以使用 `c1.is_empty()` 来检查值是否缺失，并使用 `c1.unwrap()` 来获取值。

