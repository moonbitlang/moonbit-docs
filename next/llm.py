BUILD_DIR="_build/markdown"

filenames = ["index.md", "tutorial/tour.md", "language/index.md", "language/introduction.md",
             "language/fundamentals.md", "language/methods.md", "language/error-handling.md",
             "language/packages.md", "language/tests.md", "language/docs.md", "language/ffi-and-wasm-host.md",
             "language/derive.md", "language/async-experimental.md"]

with open(f"{BUILD_DIR}/llm.md", "w") as f:
  print("# MoonBit Documentation", file=f)
  for fname in filenames:
    with open(f"{BUILD_DIR}/{fname}", "r") as g:
      print(f"<!-- path: {fname} -->", file=f)
      for line in g:
        if line.startswith('#'):
          f.write(f"#{line}")
        else:
          f.write(line)