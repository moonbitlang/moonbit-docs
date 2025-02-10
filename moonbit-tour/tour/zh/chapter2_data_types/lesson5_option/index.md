# Option类型

`Option[Char]`是表示可能存在的字符值的枚举类型，常用于处理可能缺失值的场景。其构造器包含两种可能：

- `None` 表示值缺失
- `Some(e)` 作为包装器包含实际值`e`

类型声明中的`[Char]`是类型参数，表示`Option`中值的类型为`Char`。同理可使用`Option[String]`、`Option[Double]`等类型。关于泛型的详细内容将在后续章节展开。

类型注解`Option[A]`可简写为`A?`。

您可以通过`c1.is_empty()`检查值是否缺失，使用`c1.unwrap()`获取包装值。