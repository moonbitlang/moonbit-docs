# https://github.com/executablebooks/MyST-Parser/issues/444

# Workaround suggested in https://github.com/executablebooks/MyST-Parser/issues/444#issuecomment-1179796223
from sphinx.transforms import i18n

class ModifiedIndent:
    def __init__(self, s, _):
        self.s = s
    def __radd__(self, _):
        return f"```\n{self.s}\n```"

i18n.indent = ModifiedIndent

def setup(_app): pass