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
            (r"#\|.*$", token.String),
            (r"\$\|.*$", token.String),
            (r"\'.*\'", token.Literal),
            (r"\"((\\\")|[^\"])*\"", token.String),
            (r"-?\d+(.\d+)?", token.Number),
            (words(('type', 'type!', 'enum', 'struct', 'trait'), suffix="\s"), token.Keyword),
            (words(('fn', 'if', 'else', 'while', 'for', 'loop', 'match', 'let', 'mut', 'impl', 'with', 'derive'), suffix="\s"), token.Keyword),
            (words(('return', 'break', 'continue'), suffix="\s"), token.Keyword),
            (words(('try', 'catch', 'raise'), suffix="[\s{]"), token.Keyword),
            (words(('pub', 'priv', 'pub\\(all\\)', 'pub\\(readonly\\)', 'pub\\(open\\)', 'test'), suffix="\s"), token.Keyword),
            (words(('true', 'false'), suffix='[?!,\\)\s]'), token.Keyword),
            (words(('Array', 'FixedArray', 'Int', 'Int64', 'UInt', 'UInt64', 'Option', 'Result', 'Byte', 'Bool', 'Unit', 'String', 'Show', 'Eq', 'Self'), suffix='[?!,\\)\s]'), token.Keyword),
            (r"(=>)|(\|>)|(->)|(<<)|(>>)|(==)|(&&)|(\|\|)|[\(\)\{\}\[\]:,\.=+\-*/%!?~<>;@&\|]", token.Punctuation),
            (r"[a-zA-Z_][a-zA-Z0-9_]*", token.Name),
            (r"[\s]", token.Whitespace),
        ]
    }