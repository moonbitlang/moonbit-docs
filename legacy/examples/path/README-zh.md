# 路径处理

## API

```
Path::new(s: String, platform: Platform, file_type: FileType) -> Path
```

使用指定的字符串表示形式、平台和文件类型创建一个 `Path` 类型的新实例。`Path` 类型表示一个文件路径，通过给定的参数进行构造。

```
parent(self : Path) -> String
```

获取给定路径的父目录。此函数返回一个字符串，该字符串表示所提供路径的父目录的路径。

```
is_absolute(self : Path) -> Bool
```

检查所提供的路径是否为绝对路径。绝对路径是从根目录开始的路径。

```
is_relative(self : Path) -> Bool
```

检查所提供的路径是否为相对路径。相对路径不是绝对路径，通常是相对于当前工作目录的路径。

```
has_root(self : Path) -> Bool
```

检查所提供的路径是否有根组件。根组件指的是文件系统层次结构的起始点（例如，Windows 中的驱动器号，类 Unix 系统中的根目录）。

```
file_name(self : Path) -> Option[String]
```

获取所提供路径的文件名组件。如果路径指向一个文件，此函数返回一个包含文件名的 `Option`。如果路径表示一个目录或者没有文件名，则返回 `None`。

```
append(self : Path, p : String)
```

将由字符串 `p` 表示的路径段追加到所提供的路径中。此函数通过将给定的路径段连接到原路径来扩展该路径。

```
to_string(self : Path) -> String
```

将所提供的路径转换为其字符串表示形式。此函数返回该路径的字符串表示。
