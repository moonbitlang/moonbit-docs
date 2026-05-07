# MoonBit Language Tour

view the [Chinese version](./README-zh.md) of this file.

An interactive tour to learn the MoonBit programming language.

## Get started

```sh
pnpm install
pnpm build
pnpm preview
```

open <http://localhost:3000> to view the tour.

## How to add new tour

### Add new lesson

1. Setup development environment.

   ```sh
   pnpm install
   pnpm dev
   ```

1. open <http://localhost:8080> to view the tour.

1. Create a new folder under the chapter folder. The existing convention is `lesson<n>_<lesson-name>`, but the lesson order no longer depends on the number.

1. Write the lesson content in `index.md` and lesson code in `index.mbt` under the created folder.

1. Add the lesson to `tour/toc.json`. The `path` points to the lesson folder and the `slug` controls the generated URL. Reorder lessons by moving entries in this file.

### Add new chapter

1. Create a new folder under `tour`. The existing convention is `chapter<n>_<chapter-name>`, but the chapter order no longer depends on the number.
1. Add the chapter to `tour/toc.json`. The `path` points to the chapter folder and the `slug` controls the generated URL.
1. Add new lessons following the instruction above.

## Credit

This project is highly inspired by [Gleam Language Tour](https://github.com/gleam-lang/language-tour).
