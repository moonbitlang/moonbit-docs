import os
import sys

BUILD_DIR="_build/markdown"

def collect(directory, header_level, output_file):
    def adjust_header(line, level):
        if line.startswith('#'):
            return '#' * level + line
        return line

    def process_file(filepath, level, output):
        output.write(f"\n<!-- path: {filepath} -->\n")
        with open(os.path.join(BUILD_DIR, filepath), "r") as file:
            for line in file:
                output.write(adjust_header(line, level))

    index_path = os.path.join(directory, "index.md")
    with open(index_path, "r") as index_file:
        toctree_paths = []
        collect_paths = False
        for line in index_file:
            line = line.strip()
            if "toctree" in line:
                collect_paths = True
                continue
            if collect_paths:
                if line.startswith(":"):
                    continue
                if line == "```":
                    break
                toctree_paths.append(os.path.join(directory, f"{line}.md"))

    with open(output_file, "a") as output:
        process_file(index_path, header_level, output)
        for path in toctree_paths:
            process_file(path, header_level + 1, output)

def llms_txt():
  with open(f"{BUILD_DIR}/llm.md", "w") as f:
    with open(f"{BUILD_DIR}/index.md", "r") as g:
      print(f"<!-- path: index.md -->", file=f)
      for line in g:
        f.write(line)
  
  collect("tutorial", 1, f"{BUILD_DIR}/llm.md")
  collect("language", 1, f"{BUILD_DIR}/llm.md")

def main():
  os.system("make markdown")
  llms_txt()
  for directory in ["tutorial", "language", "toolchain", "example"]:
    output_file = f"download/{directory}/summary.md"
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    if os.path.exists(output_file):
      os.remove(output_file)
    collect(directory, 0, output_file)

if __name__ == "__main__":
  main()