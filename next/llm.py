import os
from glob import glob

BUILD_DIR = "_build/markdown"


def source_path(markdown_path):
    if markdown_path.endswith(".md"):
        return markdown_path
    return f"{markdown_path}.md"


def parse_toctree_entry(line):
    line = line.strip()
    if not line or line.startswith(":") or line == "```":
        return None
    if "<" in line and line.endswith(">"):
        return line.rsplit("<", 1)[1][:-1].strip()
    return line


def toctree_paths(index_path, directory):
    paths = []
    collect_paths = False
    with open(index_path, "r") as index_file:
        for line in index_file:
            line = line.strip()
            if "toctree" in line:
                collect_paths = True
                continue
            if not collect_paths:
                continue
            if line == "```":
                collect_paths = False
                continue
            entry = parse_toctree_entry(line)
            if entry is None:
                continue
            path = os.path.normpath(os.path.join(directory, source_path(entry)))
            if any(char in path for char in "*?["):
                paths.extend(sorted(glob(path)))
            else:
                paths.append(path)
    return paths


def collect(directory, header_level, output_file):
    def adjust_header(line, level):
        if line.startswith('#'):
            return '#' * level + line
        return line

    def process_file(filepath, level, output, seen):
        if filepath in seen:
            return
        seen.add(filepath)
        output.write(f"\n<!-- path: {filepath} -->\n")
        with open(os.path.join(BUILD_DIR, filepath), "r") as file:
            for line in file:
                output.write(adjust_header(line, level))
        for path in toctree_paths(filepath, os.path.dirname(filepath)):
            process_file(path, level + 1, output, seen)

    index_path = os.path.join(directory, "index.md")
    with open(output_file, "a") as output:
        process_file(index_path, header_level, output, set())


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
