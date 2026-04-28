# MoonBit Tour

Use this reference for the interactive tour web app under `moonbit-tour/`.

## Relevant paths

- `moonbit-tour/src/`: TypeScript application source.
- `moonbit-tour/tour/index.md` and `moonbit-tour/tour/index.mbt`: default tour
  content and MoonBit examples.
- `moonbit-tour/tour/zh/index.md` and `moonbit-tour/tour/zh/index.mbt`:
  Chinese tour content and examples.
- `moonbit-tour/package.json`: pnpm scripts and dependencies.

## Workflow

1. Inspect the relevant source and tour content before editing.
2. Keep localized tour content aligned when changing shared concepts.
3. Prefer existing TypeScript, CSS, and build patterns.
4. Do not edit generated `moonbit-tour/dist/` or dependency directories.

## Commands

- Install dependencies: `just tour-install`
- Build: `just tour-build`
- Development server: `just tour-dev`
- Preview built output: `just tour-preview`
- Manual install: `cd moonbit-tour && pnpm install`
- Manual build: `cd moonbit-tour && pnpm build`
- Manual development server: `cd moonbit-tour && pnpm dev`
- Manual preview: `cd moonbit-tour && pnpm preview`
- Format tour files: `cd moonbit-tour && pnpm format`

## Validation

- For code or content changes, run `just tour-build`.
- For UI behavior changes, run the dev server and inspect the app in a browser
  when practical.

## Notes

- The app uses `@moonbit/moonpad-monaco`, Monaco, Shiki, Tailwind, and a custom
  build script.
- If pnpm dependencies are missing and network is unavailable, report the
  attempted command and the unvalidated risk.
