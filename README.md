# MoonBit Docs Website

This repository hosts the documentation website for MoonBit [docs.moonbitlang.com](https://docs.moonbitlang.com).

## Setup

We're using [Docusaurus 3](https://docusaurus.io/) for this website.

### Installation

```bash
pnpm install
```

We're using pnpm workspace, website codes are all in folder `moonbit-docs`, so make sure that all the following commands are executed in `moonbit-docs`. If you don't know how to change directory, run:

```bash
cd moonbit-docs
```

### Local Development

```
pnpm start
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

### Preview

```
pnpm build -l en && pnpm serve
```

This command makes a production build and starts a local server to preview the production build

## Write docs

### Change existing docs

Markdown files are residing at `moonbit-docs/docs`, feel free to change them as you like.

### Add new docs

1. add new doc file in folder `moonbit-docs/docs`
1. update sidebar at `moonbit-docs/sidebars.ts`
1. add corresponding chinese doc in folder `moonbit-docs/i18n/zh/docusaurus-plugin-content-docs/current`. If you don't know chinese, leave a placeholder instead.
