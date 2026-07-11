# https://github.com/executablebooks/MyST-Parser/issues/444

# Workaround suggested in https://github.com/executablebooks/MyST-Parser/issues/444#issuecomment-1179796223
from sphinx.transforms import i18n

class ModifiedIndent:
    def __init__(self, s, _):
        self.s = s
    def __radd__(self, _):
        return f"```\n{self.s}\n```"

i18n.indent = ModifiedIndent

def setup(_app):
    # The extension installs one deterministic process-global i18n helper and
    # keeps no builder/environment state. Worker processes can safely reuse it.
    return {
        "version": "0.1.0",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
