# Use and publish packages

MoonBit's build system seamlessly integrates package management and documentation
generation tools, allowing users to easily fetch dependencies from [mooncakes.io](https://mooncakes.io),
access module documentation, and publish new modules.

Before getting started, make sure you have installed [moon](https://www.moonbitlang.com/download/).

## Setup mooncakes.io account

#### NOTE
If you don't want to publish, you can skip this step.

If you don't have an account on mooncakes.io, run `moon register` and follow the
guide. If you have previously registered an account, you can use `moon login` to log in.

When you see the following message, it means you have successfully logged in:

```default
API token saved to ~/.moon/credentials.json
```

## Setup MoonBit project

Open an existing project or create a new project via `moon new <PATH>`. For example:

```shell
$ moon new .
Created username/myapp at .
```

It will generate template files in the path:

```default
├── AGENTS.md                    # Collaboration guide for agents
├── LICENSE                      # Open-source license 
├── README.mbt.md                # README file with type checking support for moonbit 
├── README.md -> README.mbt.md   # Symlink for platforms that expect README.md
├── cmd                           
│   └── main                     
│       ├── main.mbt             # MoonBit source file 
│       └── moon.pkg             # Package configuration for username/myapp/cmd/main package
├── moon.mod.json                # Module configuration for username/myapp module
├── moon.pkg                     # Package configuration for username/myapp package
├── myapp.mbt                    # MoonBit source file
├── myapp_test.mbt               # Black-box test
└── myapp_wbtest.mbt             # White-box test
```

`moon new <PATH>` generates a starter module with two packages. A module is a
publishing unit that contains multiple packages. A package represents a namespace
and a compilation unit, is defined by a package configuration file, and includes
the `.mbt` files in the same directory.

Modules and packages are identified by a special path (not the file path in the file system).
For example:

```default
username/myapp/cmd/main
─────────────────┬─────
────────┬─────   │
        │        │
        │        └─ package `username/myapp/cmd/main` within the `username/myapp` module
        │
        └────────── module path. It also defines the package `username/myapp`
```

The template contains test files, documentation, and collaboration metadata by default.
You can safely remove any template files you do not need.
The following is also a valid MoonBit project:

```default
├── moon.mod.json
├── moon.pkg
└── source.mbt
```

## Add dependencies

You can browse all available modules on [mooncakes.io](https://mooncakes.io).
Use `moon add` to add the dependencies you need, or manually edit the `deps`
field in `moon.mod.json`.

For example, to add the latest version of the [moonbit-community/starter](https://mooncakes.io/docs/moonbit-community/starter) module:

```shell
$ moon add moonbit-community/starter
```

#### NOTE
Moon also supports local dependencies. See [Dependency Management](module.md#dependency-management) for more details.

## Import packages from module

The `moonbit-community/starter` module contains a `moonbit-community/starter/rabbit` package.

After adding the [moonbit-community/starter](https://mooncakes.io/docs/moonbit-community/starter) module to your dependencies, to use the `moonbit-community/starter/rabbit` package in the `username/myapp/cmd/main` package, you need to import the package first:

```moonbit
// add this import to `cmd/main/moon.pkg`
import {
  "moonbit-community/starter/rabbit"
}

options(
  "is-main": true
)
```

#### NOTE
You can also give an alias to the imported package:

```moonbit
import {
  "moonbit-community/starter/rabbit" @alias
}
```

Now you can call the function `hello` in `rabbit` package:

```moonbit
// in `cmd/main/main.mbt`
fn main {
  // println("hello")
  @rabbit.hello()
}
```

Run your main package and see what happens in the terminal.

```shell
$ moon run cmd/main
```

## Remove dependencies

You can remove dependencies via `moon remove <module name>`.

## Publish your module

If you are ready to share your module, use `moon publish` to push a module to
mooncakes.io. There are some important considerations to keep in mind before publishing:

### Semantic versioning convention

MoonBit's package management follows the convention of [Semantic Versioning](https://semver.org/). Each module must define a version number in the format `MAJOR.MINOR.PATCH`. With each push, the module must increment the:

- MAJOR version when you make incompatible API changes
- MINOR version when you add functionality in a backward compatible manner
- PATCH version when you make backward compatible bug fixes

Additional labels for pre-release and build metadata are available as extensions to the `MAJOR.MINOR.PATCH` format.

moon implements the [minimal version selection](https://research.swtch.com/vgo-mvs), which automatically handles and installs dependencies based on the module's semantic versioning information. Minimal version selection assumes that each module declares its own dependency requirements and follows semantic versioning convention, aiming to make the user's dependency graph as close as possible to the author's development-time dependencies.

### Readme & metadata

Metadata in `moon.mod.json` and `README.md` will be shown in mooncakes.io.

Metadata consist of the following sections:

- `license`: license of this module, it following the [SPDX](https://spdx.dev/about/overview/) convention
- `keywords`: keywords of this module
- `repository`: URL of the package source repository
- `description`: short description to this module
- `homepage`: URL of the module homepage
