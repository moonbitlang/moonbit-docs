# Workspace Support

Moon workspace support lets you manage multiple modules in one repository with
one workspace manifest (`moon.work`).

## Initialize a workspace

Assume this layout:

```text
repo/
  mod_a/
    moon.mod.json
  mod_b/
    moon.mod.json
```

At `repo/`, initialize the workspace and register members:

```bash
moon work init mod_a mod_b
```

This creates `moon.work`:

```moonbit
members = [
  "./mod_a",
  "./mod_b",
]
```

## Add members

When a new module is added, register it with:

```bash
moon work use mod_c
```

## Work at workspace root

After `moon.work` is in place, run `moon` commands at the workspace root:

```bash
moon check --target all
moon test --target all
moon info
moon clean
```

These commands run in workspace context instead of a single-module context.

Some commands are module-only (for example `publish`). For those commands, run
them in a specific member module directory:

```bash
moon -C mod_a publish
```

## Sync member versions

If a member depends on another workspace member with a stale version (for
example `mod_a@0.1.0` while workspace member `mod_a` is already `0.2.0`), run:

```bash
moon work sync
```

This updates member `moon.mod.json` files to aligned workspace member versions.
