# MoonBit Language Tour

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

1. Create a new folder under the chapter folder following the naming convention `lesson<n>_<lesson-name>` (count start from 1).

1. Write the lesson content in `index.md` and lesson code in `index.mbt` under the created folder.

### Add new chapter

1. Create a new folder under `tour` following the naming convention `chapter<n>_<chapter-name>`.
1. Add new lessons following the instruction above.

## Credit

This project is highly inspired by [Gleam Language Tour](https://github.com/gleam-lang/language-tour).
