# Attribute

Attributes are annotations placed before structures in source code. They take the form `#attribute(...)`.
An attribute occupies the entire line, and newlines are not allowed within it.
Attributes do not normally affect the meaning of programs. Unused attributes will be reported as warnings.

The syntax of attributes is defined as follows:

```text
attribute ::= '#' attribute-name
            | '#' attribute-name '(' attribute-arguments ')'

attribute-name ::= LIDENT | LIDENT '.' LIDENT

attribute-arguments ::= attribute-argument (',' attribute-argument )*

attribute-argument ::= expr | LIDENT '=' expr

expr ::= LIDENT | UIDENT | STRING | 'true' | 'false'
       | LIDENT '.' LIDENT
       | LIDENT '(' attribute-arguments ')'
       | LIDENT '.' LIDENT '(' attribute-arguments ')'
```

Attributes have two categories: the built-in attributes and user-defined attributes. For example:

```
#deprecated("message")
#custom.attribute(key="value", flag=true)
```

The first attribute is a built-in attribute; it does not have a namespace prefix in the attribute name. Built-in attributes are recognized by the MoonBit compiler and have specific meanings.

The second attribute is a user-defined attribute; it has a namespace prefix `custom.` in the attribute name. User-defined attributes are ignored by the compiler, but can be used by external tools via parsing the source code.

```{note}
MoonBit is designed not to support runtime reflection. It's easy to abuse, making it impossible for toolchains (e.g., the compiler) to catch errors at compile time, which makes code harder to maintain. It also negatively impacts performance optimization.

We prefer to use compile-time code generation, keeping the benefits of static typing and performance (should also be used judiciously to avoid unnecessary complexity).
```

```{include} /language/attributes/deprecated.md
:heading-offset: 1
```

```{include} /language/attributes/alert.md
:heading-offset: 1
```

```{include} /language/attributes/alias.md
:heading-offset: 1
```

```{include} /language/attributes/label_migration.md
:heading-offset: 1
```

```{include} /language/attributes/visibility.md
:heading-offset: 1
```

```{include} /language/attributes/internal.md
:heading-offset: 1
```

```{include} /language/attributes/doc_hidden.md
:heading-offset: 1
```

```{include} /language/attributes/warnings.md
:heading-offset: 1
```

```{include} /language/attributes/must_implement_one.md
:heading-offset: 1
```

```{include} /language/attributes/inline.md
:heading-offset: 1
```

```{include} /language/attributes/external.md
:heading-offset: 1
```

```{include} /language/attributes/borrow_and_owned.md
:heading-offset: 1
```

```{include} /language/attributes/as_free_fn.md
:heading-offset: 1
```

```{include} /language/attributes/callsite.md
:heading-offset: 1
```

```{include} /language/attributes/skip.md
:heading-offset: 1
```

```{include} /language/attributes/coverage_skip.md
:heading-offset: 1
```

```{include} /language/attributes/cfg.md
:heading-offset: 1
```

```{include} /language/attributes/module.md
:heading-offset: 1
```
