# MoonBit Language Tour

An interactive tour to learn the MoonBit programming language.

## Get started

```sh
pnpm install
pnpm build
pnpm preview
```

open <http://localhost:4173> to view the tour.

## How to add new tour

### Add new lesson

1. Create a new folder under the chapter folder following the naming convention `lesson<n>_<lesson-name>` (count start from 1).
1. Write the lesson content in `index.md` and lesson code in `index.mbt` under the created folder.

To see the render result while writing lesson on the fly, follow the instruction below:

1. Setup development environment.

   ```sh
   pnpm install
   pnpm dev
   ```

1. Write the lesson content in `tour/index.md` and lesson code in `tour/index.mbt`. You can see the render result in <http://localhost:5173>

1. After you finish writing the lesson, copy `tour/index.md` and `tour/index.mbt` to the corresponding lesson folder.

### Add new chapter

1. Create a new folder under `tour` following the naming convention `chapter<n>_<chapter-name>`.
1. Add new lessons following the instruction above.

## Credit

This project is highly inspired by [Gleam Language Tour](https://github.com/gleam-lang/language-tour).
