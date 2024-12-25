import tempfile
import subprocess
from docutils.nodes import document, Node, NodeVisitor
from sphinx.application import Sphinx
from sphinx.util.typing import ExtensionMetadata
from sphinx.util import logging

logger = logging.getLogger(__name__)

def setup(app: Sphinx) -> ExtensionMetadata:
    metadata = {
        "version": "0.1.0",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
    try:
        result = subprocess.run(["moonc", '-v'], capture_output=True, check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        logger.warning("moonbit compiler is missing! No code check performed")
        return metadata
    logger.info(f"moonc version: {result.stdout.decode().strip()}")
    app.connect("doctree-read", source_read_handler)
    return metadata

class Visitor(NodeVisitor):
    def visit_literal_block(self, node : Node):
        if 'language' in node.attributes \
            and (node.attributes['language'] == 'moonbit' or node.attributes['language'] == 'mbt') \
            and 'classes' in node.attributes:
                if node.attributes['classes'].count('expr') > 0:
                    # Check as expression
                    with tempfile.NamedTemporaryFile(suffix=".mbt") as temp_file:
                        temp_file.write("fn init {\n".encode())
                        temp_file.write("\n".join(["  " + line for line in node.astext().splitlines()]).encode())
                        temp_file.write("\n}".encode())
                        temp_file.flush()
                        temp_file_path = temp_file.name

                        result = subprocess.run(["moonc", "compile", "-stop-after-parsing", temp_file_path], capture_output=True)
                        if result.returncode != 0:
                            logger.error(f"code check failed: {result.stderr.decode().strip()}")

                elif node.attributes['classes'].count('top-level') > 0:
                     # Check as top-level
                    with tempfile.NamedTemporaryFile(suffix=".mbt") as temp_file:
                        temp_file.write(node.astext().encode())
                        temp_file.flush()
                        temp_file_path = temp_file.name
                    
                        result = subprocess.run(["moonc", "compile", "-stop-after-parsing", temp_file_path], capture_output=True)
                        if result.returncode != 0:
                            logger.error(f"code check failed: {result.stderr.decode().strip()}", location=node)
    def unknown_visit(self, _node):
        return

def source_read_handler(_app : Sphinx, doctree: document):
    doctree.walk(Visitor(doctree))
