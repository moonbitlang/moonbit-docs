# Website

This website is built using [Docusaurus 3](https://docusaurus.io/), a modern static website generator.

## Clone

```
git clone https://github.com/moonbitlang/moonbit-docs.git
```

## Installation

```
pnpm install
```

## Local Development

```
$ pnpm start
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

## Build

```
$ pnpm build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

```
$ pnpm buildzh
```

This command generates chinese static content into the `build` directory and can be served using any static contents hosting service.It will overwrite the `build` code generation.If you run the `build` command before.

Switch to the `build` folder and then you can use:

```shell
pnpm run serve
```

To start the production server after build.

## Swizzle

```shell
pnpm swizzleClassic
```

This command generates the rewrite theme components code,the theme components are in the `@docusaurus/theme-classic`,if you want to custom components of this theme,you can run it.

## How to use

please see the `docs` at project folder before you add the new moonbit docs.
