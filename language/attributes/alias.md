# Alias Attribute

The `alias` attribute is used to overload operators related to indexing, or to create an alias name for a top-level function or variable. It has two forms:

- `#alias("op")`: where `op` is one of the following strings representing the indexing operators:
  - `_[_]`: for the indexing operator
  - `_[_]=_`: for the indexing assignment operator
  - `_[_:_]`: for the as view operator
- `#alias(id)`: where `id` is a identifier representing the alias name.

Both forms allowed additional arguments:

- `visibility="modifier"`

  A labeled argument, changes the visibility of the alias. The `modifier` can be `pub` or `priv`. If not specified, the alias will have the same visibility as the original function or variable.
- `deprecated` or `deprecated="message"`

  Marks the alias as deprecated. If a message is provided, it will be displayed as a warning when the alias is used.

To graceful migration from old API to new API, you can rename the old API directly, and create an alias with the old name, mark it as deprecated. For
example:

```moonbit
#alias(old_name, deprecated)
fn new_name() -> Unit {
  ()
}
```
