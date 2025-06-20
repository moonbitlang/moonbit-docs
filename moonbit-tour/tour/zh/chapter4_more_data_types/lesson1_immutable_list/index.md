# 不可变列表

不可变列表位于包 `@list` 中。

它可以是：

- `Empty` : 一个空列表
- `More` : 一个元素和列表的其余部分。

可以用 `@list.empty()` 和 `@list.construct(..)` 来构造列表。还可以用 `xs.prepend(x)` 来往列表头部追加元素。
