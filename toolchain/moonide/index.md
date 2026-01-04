# MoonBit Agent IDE

## Overview

`moon ide` is a specialized CLI toolset for navigating, understanding, and exploring MoonBit codebases. It provides semantic-aware tools for code discovery using the compiler's knowledge of your project structure.

These commands use semantic analysis rather than text matching, making them more precise than grep-based searching for code navigation tasks.

### Available Commands

- **`moon ide peek-def`**: Locate symbol definitions with inline context
- **`moon ide find-references`**: Locate all usages of a symbol across the project
- **`moon ide outline`**: Get a structural overview of files or packages
- **`moon ide doc`**: Discover and explore APIs with documentation

## Symbol Syntax

All `moon ide` subcommands accept a `<symbol>` argument using these patterns:

**Basic symbols:**

- `[@pkg.]symbol` - Symbol in a package (e.g. `parse_int`, `Array`)
- If `@pkg.` is omitted, searches current package and prelude

**Type members:**

- `[@pkg.]Type::member` - Type methods, struct fields, enum variants, trait methods
- Examples: `Array::length`, `@http.Request::new`, `Option::None`

Package prefix `@pkg.` is optional for symbols in the current package and standard library.

## `moon ide peek-def` - View Symbol Definitions

Quickly locate symbol definitions with surrounding context. This is faster and more precise than grepping for declarations.

### Usage

```bash
moon ide peek-def <symbol> [-loc filename:line[:col]]
```

**Two modes:**

1. **Global search** (no `-loc`): Searches the entire project using the symbol syntax described above
2. **Contextual search** (`-loc` provided): Matches `<symbol>` as a substring at the specified location
   - Line number must be precise; column is optional (used as a hint)
   - The `<symbol>` argument is matched as plain text, not parsed as symbol syntax
   - Useful when a symbol name is ambiguous or appears in multiple contexts

### Examples

```bash
$ moon ide peek-def Agent
Found 1 symbols matching 'Agent':

`pub (all) struct Agent` in package moonbitlang/maria/agent at ./agent/agent.mbt:17-47

17 | ///|
   | /// Represents an AI agent that interacts with language models and executes tools.
...|
   | pub(all) struct Agent {
...|
...| }
```

```bash
$ moon ide peek-def Agent -loc ./maria.mbt:7
Definition found at file ./maria/agent/agent.mbt
   | ///
   | /// The `Agent` struct encapsulates the complete state and behavior of an AI agent,
...|
24 | pub(all) struct Agent {
   |                 ^^^^^
   |   /// UUID generator for creating unique identifiers.
...|
```

## `moon ide find-references` - Track All Usages

Discover where and how a symbol is used throughout your codebase.

### Usage

```bash
moon ide find-references <symbol>
```

Note: The `-loc` argument is not yet supported. Always searches globally.

### Example

```bash
$ moon ide find-references Agent
`pub (all) struct Agent` in package moonbitlang/maria/agent at ./agent/agent.mbt:17-47
17 | ///|
   | /// Represents an AI agent that interacts with language models and executes tools.
...|
   | pub(all) struct Agent {
...|
...| }
Found 98 references of this symbol:
./agent/agent_tool.mbt:41:8-41:13:
   | /// * `agent` : The agent instance whose tools will be enabled or disabled.
   | /// * `tool_names` : A set containing the names of tools that should be enabled.
   | ///   Tools not in this set will be disabled.
41 | pub fn Agent::set_enabled_tools(
   |        ^^^^^
   |   agent : Agent,
   |   tool_names : Set[String],
...
```

## `moon ide outline` - Get Structural Overview

Quickly scan the structure of a file or package to understand its organization.

### Usage

```bash
moon ide outline <path/to/file_or_directory>
```

Two modes:

- `moon ide outline path/to/file.mbt` - Outline a specific file
- `moon ide outline path/to/directory` - Outline all `.mbt` files in the package

### Examples

**Package outline** - See all files and their top-level symbols:

```bash
moon ide outline .
maria.mbt:
 L05 | pub struct Maria {
       ...
 L71 | pub fn Maria::close(self : Maria) -> Unit {
       ...
 L84 | pub async fn Maria::start(self : Maria, prompt? : String) -> Unit {
```

**File outline** - Detailed view of a single file:

```bash
$ moon ide outline ./internal/readline/readline.mbt
 L0002 | priv struct Edit {
         ...
 L0008 | pub enum KeyName {
         ...
 L0045 | pub struct Key {
         ...
 L1369 | pub async fn Interface::start(self : Interface) -> Unit {
         ...
 L1383 | pub async fn Interface::read_line(self : Interface) -> String {
         ...
 L1390 | pub async fn Interface::read_key(self : Interface) -> Key {
         ...
```

## `moon ide doc` - Discover and Explore APIs

Query documentation and discover available symbols, packages, and APIs.

### Usage

```bash
moon ide doc '<query>'
```

### Query Syntax

The query syntax is specialized for symbol and package discovery:

**Empty query** - List available packages or symbols:

- `moon ide doc ''`
  - In a module: Shows all available packages (including dependencies and `moonbitlang/core`)
  - In a package: Shows all symbols in current package
  - Outside package: Shows all available packages

**Lookup by name:**

- `moon ide doc "[@pkg.]function_name"` - Find functions or values
- `moon ide doc "[@pkg.]TypeName"` - Find types (builtin types don't need prefix)
- `moon ide doc "[@pkg.]Type::member"` - Find type methods or fields
- `moon ide doc "[@pkg.]Type::member"` - Find type methods or fields

**Package exploration:**

- `moon ide doc "@pkg"` - List all exported symbols in a package
- `moon ide doc "@encoding/utf8"` - Works with nested packages
- Examples: `moon ide doc "@json"`, `moon ide doc "@buffer"`

**Globbing** - Use `*` wildcard for partial matches:

- `moon ide doc "String::*rev*"` - Find all String methods containing "rev"
- `moon ide doc "*parse*"` - Find all symbols with "parse" in the name

### Examples

**Search for type methods:**

```bash
# Search for String methods in standard library:
$ moon ide doc "String"

type String

  pub fn String::add(String, String) -> String
  # ... more methods omitted ...
```

**Explore a package:**

```bash
$ moon ide doc "@buffer"
moonbitlang/core/buffer

fn from_array(ArrayView[Byte]) -> Buffer
# ... omitted ...
```

**Query a specific function:**

```bash
$ moon ide doc "@buffer.new"
package "moonbitlang/core/buffer"

pub fn new(size_hint? : Int) -> Buffer
  Creates ... omitted ...
```

**Use globbing to find related functions:**

```bash
$ moon ide doc "String::*rev*"
package "moonbitlang/core/string"

pub fn String::rev(String) -> String
  Returns ... omitted ...
  # ... more

pub fn String::rev_find(String, StringView) -> Int?
  Returns ... omitted ...
```
