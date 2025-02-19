# 字符处理

使用 Moonbit 实现字符串工具。

## API

此函数用于检查给定的字符 `c` 是否为有效字符。它返回一个布尔值，指示该字符是否有效。

```moonbit
is_valid(c: Char) -> Bool
```

此函数用于判断字符 `c` 是否为字母。如果 `c` 是字母，则返回 `true`，否则返回 `false`。

```moonbit
is_alpha(c : Char) -> Bool
```

此函数用于检查字符 `c` 是否为数字。如果 `c` 是数字，则返回 `true`，否则返回 `false`。

```moonbit
is_numeric(c : Char) -> Bool
```

此函数用于判断字符 `c` 是字母还是数字。如果 `c` 是字母数字字符，则返回 `true`，否则返回 `false`。

```moonbit
is_alphanumeric(c : Char) -> Bool
```

此函数用于将字符 `c` 转换为小写形式，并返回转换后的小写字符。

```moonbit
to_lower(c : Char) -> Char
```

此函数用于将字符 `c` 转换为大写形式，并返回转换后的大写字符。

```moonbit
to_upper(c : Char) -> Char
```

此函数用于检查字符 `c` 是否为空白字符（如空格或制表符）。如果 `c` 是空白字符，则返回 `true`，否则返回 `false`。

```moonbit
is_whitespace(c : Char) -> Bool
```

此函数返回字符 `c` 的下一个字符。如果存在下一个字符，则将该字符包装在 `Some` 中返回；否则返回 `None`。

```moonbit
next(c : Char) -> Option[Char]
```

此函数返回字符 `c` 的前一个字符。如果存在前一个字符，则将该字符包装在 `Some` 中返回；否则返回 `None`。

```moonbit
prev(c : Char) -> Option[Char]
```
