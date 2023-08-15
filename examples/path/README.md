# Path
## API
```
Path::new(s: String, platform: Platform, file_type: FileType) -> Path
```
Creates a new instance of the Path type with the specified string representation, platform, and file type. The Path type represents a file path and is constructed using the given parameters.
```
parent(self : Path) -> String
```
Retrieves the parent directory of the given path. This function returns a string representing the path of the parent directory of the provided path.
```
is_absolute(self : Path) -> Bool
```
Checks whether the provided path is an absolute path. An absolute path is a path that starts from the root directory.
```
is_relative(self : Path) -> Bool
```
Checks whether the provided path is a relative path. A relative path is a path that is not absolute and is typically relative to the current working directory.
```
has_root(self : Path) -> Bool
```
Checks whether the provided path has a root component. The root component refers to the starting point of the file system hierarchy (e.g., drive letter in Windows, root directory in Unix-like systems).
```
file_name(self : Path) -> Option[String]
```
Retrieves the file name component of the provided path. If the path points to a file, this function returns an Option containing the file name. If the path represents a directory or does not have a file name, None is returned.
```
append(self : Path, p : String)
```
Appends a path segment represented by the string p to the provided path. This function extends the path by concatenating the given segment to it.
```
to_string(self : Path) -> String
```
Converts the provided path to its string representation. This function returns the string representation of the path.