# 循环

在此示例中，我们使用 for 循环和 while 循环遍历一个数组。

## For 循环表达式

for 循环类似于 C 风格的 for 循环：

```
for init; condition; increment {
    // 循环体
}
```

循环在开始之前初始化 `init` 部分中的变量。当循环开始时，它测试 `condition`，如果 `condition` 为真，则执行循环体。之后，它运行 `increment` 表达式并重复此过程，直到条件为假。

在 MoonBit 中，for 循环比 C 风格的 for 循环更具表现力。我们将在后面的章节中解释。

## While 循环表达式

while 循环也类似于 C 风格的 while 循环。

它在执行循环体之前测试条件。如果条件为真，
它执行循环体并重复此过程，直到条件为假。

MoonBit 还支持在循环中使用 `continue` 和 `break` 语句。
