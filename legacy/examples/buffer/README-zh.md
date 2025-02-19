# 缓冲区

## API

创建一个具有指定初始容量的 `Buffer` 类型的新实例。该容量决定了用于存储 `T` 类型元素的缓冲区的初始大小。类型 `T` 必须实现 `Default` 特征以提供一个默认值。

```moonbit
Buffer::new[T : Default](capacity : Int) -> Buffer[T]
```

返回缓冲区的当前容量。该容量表示缓冲区在不进行扩容的情况下能够容纳的最大元素数量。

```moonbit
capacity[T](self : Buffer[T]) -> Int
```

返回当前存储在缓冲区中的元素数量。此方法提供了缓冲区中实际存在的元素的计数。

```moonbit
length[T](self : Buffer[T]) -> Int
```

将一个 `T` 类型的元素追加到缓冲区的末尾。如果缓冲区已达到其容量，可能会自动进行扩容以容纳新元素。

```moonbit
append[T : Default](self : Buffer[T], value : T)
```

截断当前缓冲区，并将另一个缓冲区 `another` 的内容复制到其中。缓冲区的原始容量保持不变。

```moonbit
truncate[T : Default](self : Buffer[T], another : Buffer[T])
```

清除缓冲区中的所有元素，并将其长度重置为零。容量保持不变。

```moonbit
clear[T : Default](self : Buffer[T])
```

通过清除缓冲区的内容并将其容量设置为指定值来重置缓冲区。当你想以不同的容量重用现有的缓冲区时，这很有用。

```moonbit
reset[T : Default](self : Buffer[T], capacity : Int)
```

使用 `Show` 特征将缓冲区的内容打印到标准输出。为了使用此方法，类型 `T` 必须实现 `Show` 特征。

```moonbit
println[T : Show](self: Buffer[T])
```
