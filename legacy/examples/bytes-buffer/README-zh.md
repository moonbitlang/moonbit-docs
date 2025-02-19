# 字节缓冲区

## API

```moonbit
pub func Buffer::new(size : Int) -> Buffer
```

创建一个具有指定大小的新缓冲区。

```moonbit
pub func capacity(self : Buffer) -> Int
```

返回缓冲区的总容量。

```moonbit
pub func length(self : Buffer) -> Int
```

返回缓冲区的当前长度。

```moonbit
pub func append_int(self : Buffer, value : Int)
```

将一个整数值追加到缓冲区中。

```moonbit
pub func truncate(self : Buffer, another: Buffer)
```

截断当前缓冲区，并将其内容替换为另一个缓冲区的内容。

```moonbit
pub func clear(self : Buffer)
```

清除缓冲区的内容。

```moonbit
pub func reset(self : Buffer, capacity : Int)
```

使用新的容量重置缓冲区。

```moonbit
pub func to_bytes(self : Buffer) -> Bytes
```

将缓冲区的内容转换为字节。

```moonbit
pub func bytes_to_int(bytes : Bytes, start : Int) -> Int
```

将一段字节转换为整数。
