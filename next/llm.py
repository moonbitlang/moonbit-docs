import os
import pickle

BUILD_DIR = "_build/markdown"
ENV_PATH = "_build/doctrees/environment.pickle"


def load_sphinx_env():
    with open(ENV_PATH, "rb") as file:
        return pickle.load(file)


def collect(directory, header_level, output_file):
    def adjust_header(line, level):
        if line.startswith('#'):
            return '#' * level + line
        return line

    def process_doc(docname, level, output, seen):
        if docname in seen:
            return
        seen.add(docname)
        filepath = f"{docname}.md"
        output.write(f"\n<!-- path: {filepath} -->\n")
        with open(os.path.join(BUILD_DIR, filepath), "r") as file:
            for line in file:
                output.write(adjust_header(line, level))
        for child in env.toctree_includes.get(docname, []):
            process_doc(child, level + 1, output, seen)

    env = load_sphinx_env()
    root_doc = f"{directory}/index"
    with open(output_file, "a") as output:
        process_doc(root_doc, header_level, output, set())


def llms_txt():
  with open(f"{BUILD_DIR}/llm.md", "w") as f:
    with open(f"{BUILD_DIR}/index.md", "r") as g:
      print(f"<!-- path: index.md -->", file=f)
      for line in g:
        f.write(line)
  
  collect("tutorial", 1, f"{BUILD_DIR}/llm.md")
  collect("language", 1, f"{BUILD_DIR}/llm.md")

def main():
  if os.system("make markdown") != 0:
    raise SystemExit("make markdown failed")
  llms_txt()
  for directory in ["tutorial", "language", "toolchain", "example"]:
    output_file = f"download/{directory}/summary.md"
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    if os.path.exists(output_file):
      os.remove(output_file)
    collect(directory, 0, output_file)

if __name__ == "__main__":
  main()
