# 字符串

使用 MoonBit 实现字符串工具。

## API

将一个字符串进行分割，并返回分割后的字符串数组以及该数组的长度。

```
split(String, Char) -> (Array[String], Int)
```

获取字符串从起始位置到结束位置的子字符串。

```
sub_string(String, start: Int, end: Int) -> Option[String]
```

移除字符串首尾的指定字符。

```
trim(String, Char) -> String
```

获取首次匹配项的位置。

```
index_of(s: String, pattern: String) -> Option[Int]
```

获取最后一次匹配项的位置。

```
last_index_of(s: String, pattern: String) -> Option[Int]
```

判断字符串 `s` 是否包含子字符串 `sub`。

```
contains(s: String, sub: String) -> Bool
```

返回指定位置的字符。

```
char_at(String, position: Int) -> Option[Char]
```

将一个字符串转换为字符数组。

```
to_char_array(String) -> Array[Char]
```

为字符串创建一个迭代器。

```
iter(String) -> Iterator
next(Iterator) -> Option[Char]
```
