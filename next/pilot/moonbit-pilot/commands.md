# Commands

## Markdown Files as Executables

Markdown files are executable, and the runtime environment is MoonBit Pilot!

## Background

If you frequently have repetitive commands to execute, such as:


```markdown
Run `pnpm lint --fix` until all errors are fixed
```

Copy-pasting this phrase every time becomes tedious, especially when you have many prompts to execute. MoonBit Pilot provides a solution to make managing your daily work prompts simple.

## Final Effect

Let's look at the final way to run the prompt:

```bash
/lint_fix
```

Here, you only need to run a `/lint_fix` command to complete the execution of the above prompt.

## Implementation

In your project's `.moonagent/commands` directory, create a `lint_fix.md` file with the following content:

```markdown
Run pnpm lint --fix until all errors are fixed
```

Then you can use `lint_fix` as a command in the moon pilot command line, with auto-completion support.

## Handling Dynamic Prompts

What if you want the command to be changeable? You can modify the file content like this:

```markdown
Run {{args[0] or "pnpm lint --fix"}} until all errors are fixed
```

Explanation:

1. `args` represents positional arguments, which can be referenced using `[index]`
2. `kwargs` represents key-value pair arguments, which can be referenced using `kwargs.<key>`
3. `{{}}` is used to render a value

Let's see how to use it:

```bash
act ▶ /lint_fix "echo hello"
```

You can also use named parameters:

```markdown
Run {{kwargs.command or "pnpm lint --fix"}} until all errors are fixed
```

Then use it like this:

```bash
act ▶ /lint_fix command="echo hello"
```

Notice that the value should be quote with `"`.

## Complex Scripts

Here's an example of a more complex script to help you quickly complete complex engineering requirements:

```markdown
# {{ kwargs.title or "Development Plan" }}

## Objective
{{ kwargs.objective or "Define the main objective here" }}

## Tasks
{% for task in args %}
- {{ task }}
{% endfor %}

## Parameters
{% for key, value in kwargs %}
- **{{ key }}**: {{ value }}
{% endfor %}

## Summary
Total tasks: {{ args|length }}
Total parameters: {{ kwargs|length }}
```

Of course, for convenience, it's reasonable to minimize the number of parameters.

## Additional Benefits

Besides completing prompt management and improving execution efficiency, this actually means you can better use IDE editors to write complex prompts and make debugging easier. 