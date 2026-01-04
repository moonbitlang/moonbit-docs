# Working With Module And Package

In MoonBit, code is organized into modules and packages to promote code reuse and maintainability. Like many modern programming languages, MoonBit also provides two important tools to assist with this: a build system and a package registry.

- The build system, `moon`, helps you manage your project's dependencies, build processes, and publish modules to the package registry. You can find a tutorial in [MoonBit's build system tutorial](https://docs.moonbitlang.com/en/latest/toolchain/moon/tutorial.html).

- The package registry, [mooncakes.io](https://mooncakes.io), is a platform where you can find, share, and browse documentation for packages. **The documentation for the standard library API, [`moonbitlang/core`](https://mooncakes.io/docs/moonbitlang/core), is also hosted as a regular module on this website.**

This tour does not cover how to use `moon` or mooncakes.io in detail. For more information, refer to the links above. Don't worry—these tools are only needed when working on a MoonBit project. You can continue with this tutorial and explore them later.

## Access API via `@path/to/pkg.func` syntax

Here is some essential information you need to know:

- **Module**

    A module is the smallest unit that can be introduced as a dependency in your program. 
    A module can contain multiple packages and can be published to the package registry.  
    Each module has a unique path, for example, `moonbitlang/core` or `moonbitlang/x`.

- **Package**

    A package is a part of a module. It hides implementation details and exposes useful APIs for others to use.  
    Each package also has a unique path, which begins with its module's path, e.g., `moonbitlang/core/math`.  


After you introduce a module as a dependency (for example, `moonbitlang/x`) and import the package you want to use (such as `moonbitlang/x/fs`), you can access its functions using the `@path/to/pkg.func` syntax. For instance, use `@moonbitlang/x/fs.create_dir` (or `@fs.create_dir` if you assigned an alias) to call the `create_dir` function.

**Note**: The `moonbitlang/core` module is special—it's added as a dependency and its packages are imported by default.

## Local Module Dependencies

In addition to modules from mooncakes.io, you can also use local modules as dependencies. This is particularly useful when:

- Developing multiple related modules on your local machine
- Working with modules that are not yet published
- Testing changes across multiple modules

To add a local dependency, edit the `deps` field in your `moon.mod.json` file:

```json
{
  "name": "username/hello",
  "deps": {
    "foo/bar": {
      "path": "../../path/to/foo-module"
    }
  }
}
```

The `path` should be a relative path to the directory containing the local module's `moon.mod.json` file.

Once declared, you can import packages from the local module in your `moon.pkg.json`, just like any other module:

```json
{
  "import": [
    {
      "path": "foo/bar",
      "alias": "bar"
    }
  ]
}
```

Now you can use the local module's functions with `@bar.function_name()`.
