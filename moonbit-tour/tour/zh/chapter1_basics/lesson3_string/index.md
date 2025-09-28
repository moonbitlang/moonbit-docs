# 字符串和字符

[`String`](https://mooncakes.io/docs/moonbitlang/core/string) 是以UTF-16编码的字符序列。在MoonBit中，字符串是不可变的，这意味着你不能修改字符串内部的元素。

[`Char`](https://mooncakes.io/docs/moonbitlang/core/char) 是单个Unicode字符，用单引号表示，例如 `'a'` 。

## 转义序列和Unicode

为了表示特殊字符，MoonBit在字符串和字符字面量中支持C风格的转义序列，例如 `\n` （换行）、 `\t` （制表符）、 `\\` （反斜杠）、 `\"` （双引号）和 `\'` （单引号）。

Unicode转义字符也受支持。你可以使用 `\u{...}` （其中 `...` 表示Unicode字符的十六进制代码）通过代码点来表示Unicode字符。

## 字符串插值和连接

MoonBit还支持字符串插值，写作 `\{变量}` ，这允许你将表达式嵌入到字符串中。你也可以使用 `+` 运算符来连接字符串。

`String` 在实际程序中是一个复杂的类型。本课介绍基础知识，但还有许多高级特性将在后面介绍。
