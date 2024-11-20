from pygments.lexer import RegexLexer, words
import pygments.token as token
from sphinx.application import Sphinx
from sphinx.util.typing import ExtensionMetadata

def setup(app: Sphinx) -> ExtensionMetadata:
    app.add_lexer("moonbit", MoonBitLexer)
    app.add_lexer("mbt", MoonBitLexer)
    return {
        "version": "0.1.0",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }

class MoonBitLexer(RegexLexer):
    name = "MoonBit"

    tokens = {
        'root': [
            (r"//.*$", token.Comment),
            (words(('fn', 'if', 'else', 'while', 'for', 'loop', 'match', 'let', 'mut', 'trait', 'impl', 'with'), suffix="\s"), token.Keyword),
            (words(('true', 'false'), suffix='\s'), token.Keyword),
            (words(('Array', 'FixedArray', 'Int', 'Int64', 'UInt', 'UInt64', 'Option', 'Result', 'Byte', 'Bool'), suffix='\s'), token.Keyword),
            (r"(=>)|(\|>)|(->)|[\(\)\{\}\[\]:,\.=+\-*/]", token.Punctuation),
            (r"-?\d+(.\d+)?", token.Number),
            (r"[a-zA-Z_][a-zA-Z0-9_]*", token.Name),
            (r"\'.?\'", token.Literal),
            (r"\"[^\"]*\"", token.String),
            (r"#\|.*$", token.Text),
            (r"[\s]", token.Whitespace),
        ]
    }