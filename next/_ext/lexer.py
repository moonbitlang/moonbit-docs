from pygments.lexer import RegexLexer, words, include, bygroups
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
            (r"#.*$", token.Comment.Preproc),
            (r"//.*$", token.Comment.Single),
            (r"b?\'.*\'", token.Literal),
            (r"#\|.*$", token.String),
            (r"(b)(\")", bygroups(token.String.Affix, token.String), "string.inline"),
            ("\"", token.String, "string.inline"),
            (r"\$\|", token.String, "string.multiline"),
            (r"0(b|B)[01]+", token.Number.Bin),
            (r"0(o|O)[0-7]+", token.Number.Oct),
            (r"0(x|X)[0-9a-fA-F][0-9a-fA-F_]*\.[0-9a-fA-F][0-9a-fA-F_]*(P|p)(\+|\-)?[0-9][0-9]*", token.Number.Float),
            (r"0(x|X)[0-9a-fA-F][0-9a-fA-F_]*\.?(P|p)(\+|\-)?[0-9][0-9]*", token.Number.Float),
            (r"0(x|X)[0-9a-fA-F][0-9a-fA-F_]*\.[0-9a-fA-F][0-9a-fA-F_]*", token.Number.Float),
            (r"0(x|X)[0-9a-fA-F][0-9a-fA-F_]*\.", token.Number.Float),
            (r"0(x|X)[0-9a-fA-F][0-9a-fA-F_]*", token.Number.Hex),
            (r"\d(_|\d)*U?L", token.Number.Integer.Long),
            (r"\d(_|\d)*U?", token.Number.Integer),
            (r"\d+(.\d+)?", token.Number),
            (words(('type', 'type!', 'enum', 'struct', 'trait', 'typealias', 'traitalias'), suffix=r"\b"), token.Keyword.Declaration),
            (words(('async', 'fn', 'const', 'let', 'mut', 'impl', 'with', 'derive', 'fnalias'), suffix=r"\b"), token.Keyword.Declaration),
            (words(('self', 'Self'), suffix=r"\b"), token.Keyword),
            (words(('guard', 'if', 'while', 'match', 'else', 'loop', 'for', 'in', 'is'), suffix=r"\b"), token.Keyword),
            (words(('return', 'break', 'continue'), suffix=r"\b"), token.Keyword),
            (words(('try', 'catch', 'raise', 'noraise'), suffix=r"\b"), token.Keyword),
            (r"\bas\b", token.Keyword),
            (words(('extern', 'pub', 'priv', 'pub(all)', 'pub(readonly)', 'pub(open)', 'test'), suffix=r"\b"), token.Keyword),
            (words(('true', 'false'), suffix=r"\b"), token.Keyword.Constant),
            (words(('Eq', 'Compare', 'Hash', 'Show', 'Default', 'ToJson', 'FromJson'), suffix=r"\b"), token.Name.Builtin),
            (words(('Array', 'FixedArray', 'Int', 'Int64', 'UInt', 'UInt64', 'Option', 'Result', 'Byte', 'Bool', 'Unit', 'String', 'Float', 'Double'), suffix=r"\b"), token.Name.Builtin),
            (words(('+', '-', '*', '/', '%', '|>', '>>', '<<', '&&', '||', '&', '|', '<', '>', '==')), token.Operator),
            (words(('not', 'lsl', 'lsr', 'asr', 'op_add', 'op_sub', 'op_div', 'op_mul', 'op_mod', '...')), token.Operator.Word),
            # @namespace.
            (r"@[A-Za-z][A-Za-z0-9_/]*\.", token.Name.Namespace),
            # Function alias
            (r"([a-z][A-Za-z0-9_]*)(\s+)(as)(\s+)([a-z][A-Za-z0-9_]*)", bygroups(token.Name.Function, token.Whitespace, token.Punctuation, token.Whitespace, token.Name.Function)),
            (r"([A-Za-z][A-Za-z0-9_]*)(::)([A-Za-z][A-Za-z0-9_]*)(\s+)(as)(\s+)([a-z][A-Za-z0-9_]*)", bygroups(token.Name.Class, token.Punctuation, token.Name.Function, token.Whitespace, token.Punctuation, token.Whitespace, token.Name.Function)),
            # Type::function
            (r"([A-Za-z][A-Za-z0-9_]*)(::)([A-Za-z][A-Za-z0-9_]*)", bygroups(token.Name.Class, token.Punctuation, token.Name.Function)),
            # function(
            (r"([a-z][A-Za-z0-9_]*)(?=!?\()", token.Name.Function),
            ("Error", token.Name.Exception),
            (r"(=>)|(->)|[\(\)\{\}\[\]:,\.=!?~;]", token.Punctuation),
            (r"[a-z][a-zA-Z0-9_]*", token.Name.Variable),
            (r"[A-Z_][a-zA-Z0-9_]*", token.Name.Class),
            (r"[\s]", token.Whitespace),
        ],
        'string.inline': [
            include('escape'),
            (r"\\{", token.String.Escape, "interpolation"),
            ("\"", token.String, "#pop"),
            (r".", token.String.Double)
        ],
        'string.multiline': [
            include('escape'),
            (r"\\{", token.String.Escape, "interpolation"),
            (r"\Z", token.String, "#pop"),
            (r".", token.String)
        ],
        'interpolation': [
            (r"}", token.String.Escape, "#pop"),
            include('root')
        ],
        'escape': [
            (r"\\[0\\tnrb\"']", token.String.Escape),
            (r"\\x[0-9a-fA-f]{2}", token.String.Escape),
            (r"\\u[0-9a-fA-f]{4}", token.String.Escape),
            (r"\\u[0-9a-fA-f]*", token.String.Escape),
        ]
    }