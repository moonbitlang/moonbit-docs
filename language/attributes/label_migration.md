# `label_migration` Attribute

The `#label_migration` attribute is used to help you safely evolve your API
by warning users during the transition period.

It has three following forms:

- `#label_migration(id, fill=true, msg="message")`

  The `fill` argument is used when you want to refactor an optional parameter.
  You can use `fill=true` when you want to eventually make an optional
  parameter required. You can use `fill=false` when you want to eventually
  remove an optional parameter.

  The `msg` argument is an string that provides additional information about the migration.
  ```moonbit
  #label_migration(x, fill=true)
  #label_migration(y, fill=false)
  fn label_migration_fill(x? : Int = 0, y? : Int = 1) -> Int {
    x + y
  }
  ```
- `#label_migration(id, allow_positional=true, msg="message")`

  The `allow_positional` argument is used when you want a labelled parameter to be
  used without its label being provided. When the parameter is used positionally
  (without a label), the compiler reports a warning. This is useful when you want to change a positional parameter
  to a labelled parameter without breaking the downstream code.

  The `msg` argument is an string that provides additional information about the migration.
  ```moonbit
  #label_migration(x, allow_positional=true)
  fn label_migration_allow_positional(x~ : Int) -> Int {
    x
  }
  ```
- `#label_migration(id, alias=new_id, msg="message")`

  The alias argument allows you to provide an alternative name to a labelled
  parameter. This is useful when renaming a parameter to maintain backward
  compatibility. If a warning message is provided, the compiler warns when
  using the alias; otherwise, the alias can be used without warnings.

  The `msg` argument is an string that provides additional information about the migration.
  ```moonbit
  #label_migration(x, alias=xx)
  #label_migration(x, alias=y, msg="warning")
  fn label_migration_alias(x~ : Int) -> Int {
    x
  }
  ```
