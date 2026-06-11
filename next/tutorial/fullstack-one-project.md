# Fullstack in One MoonBit Project

This tutorial builds a small fullstack app in one MoonBit module.

You will implement one shared validation rule set and use it in both places:

- `frontend/`: show local warnings and call backend
- `backend/`: validate again and return JSON response

The key is `supported-targets`:

- `frontend/` is `js`
- `backend/` is `native`
- `shared/` is target-agnostic

## Prerequisites

- MoonBit toolchain installed
- `hurl` installed for API testing

## Step 1: Create the module

```bash
moon new fullstack_one_project
cd fullstack_one_project
moon add moonbitlang/async@0.19.2
moon add moonbit-community/rabbita
```

Project layout:

```text
fullstack_one_project
├── Makefile
├── moon.mod.json
├── backend
│   ├── api.hurl
│   ├── index.html
│   ├── main.mbt
│   └── moon.pkg
├── frontend
│   ├── main.mbt
│   └── moon.pkg
└── shared
    ├── moon.pkg
    ├── shared_test.mbt
    └── task.mbt
```

Module config:

```{literalinclude} /sources/fullstack-one-project/moon.mod.json
:language: json
```

## Step 2: Implement shared domain validation

Define request/response types with `derive(ToJson, FromJson)` and one `suberror`-based validator in `shared/`.
Both frontend and backend import this package.

```{literalinclude} /sources/fullstack-one-project/shared/moon.pkg
:language: moonbit
```

```{literalinclude} /sources/fullstack-one-project/shared/task.mbt
:language: moonbit
:start-after: start shared-model
:end-before: end shared-model
```

## Step 3: Implement the frontend (`js`)

Frontend behavior:

- validate title locally with shared rules
- if valid, `POST` to backend `/submit`
- display backend response text

```{literalinclude} /sources/fullstack-one-project/frontend/moon.pkg
:language: moonbit
```

```{literalinclude} /sources/fullstack-one-project/frontend/main.mbt
:language: moonbit
:start-after: start frontend-main
:end-before: end frontend-main
```

## Step 4: Implement the backend (`native`)

Backend behavior:

- serve `GET /` from static `backend/index.html`
- serve `GET /frontend.js` from frontend build output
- handle `POST /submit` with shared validation and JSON response

```{literalinclude} /sources/fullstack-one-project/backend/moon.pkg
:language: moonbit
```

```{literalinclude} /sources/fullstack-one-project/backend/index.html
:language: html
```

```{literalinclude} /sources/fullstack-one-project/backend/main.mbt
:language: moonbit
:start-after: start backend-main
:end-before: end backend-main
```

## Step 5: Use Makefile shortcuts

```{literalinclude} /sources/fullstack-one-project/Makefile
:language: makefile
```

Common workflow:

```bash
make build-frontend
make run-backend
```

Then open `http://127.0.0.1:8080/` in a browser.

## Step 6: Test API with Hurl

Hurl test suite:

```{literalinclude} /sources/fullstack-one-project/backend/api.hurl
:language: hurl
```

Run it:

```bash
make api-test
```

This verifies:

- static `GET /` and `GET /frontend.js`
- accepted submit (`200`)
- rejected submit (`400`) for invalid titles
- rejected submit (`400`) for malformed JSON input

## Step 7: Verify everything

```bash
make verify-all
```

This runs:

- `moon check --deny-warn --target all`
- `moon test --deny-warn --target all`
- Hurl API tests

You now have one executable project where frontend and backend share the same validation contract and error model.
