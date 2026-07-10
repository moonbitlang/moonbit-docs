import re
from typing import Any

from docutils import nodes
from sphinx import addnodes
from sphinx.application import Sphinx
from sphinx.util.docutils import SphinxDirective
from sphinx.util.nodes import make_id
from sphinx.util.typing import ExtensionMetadata


_PRODUCTION_RE = re.compile(r"^\s*([A-Za-z][A-Za-z0-9-]*)\s*::=\s*(.*)$")
_CONTINUATION_RE = re.compile(r"^(\s+)(\S.*)$")
_PART_RE = re.compile(r'"(?:\\.|[^"\\])*"|`(?:~?[\w-]+:)?[\w-]+`')


class GrammarNode(nodes.General, nodes.Body, nodes.FixedTextElement):
    pass


def _visit_grammar_html(translator: Any, node: GrammarNode) -> None:
    translator.body.append(translator.starttag(node, "pre", suffix=""))


def _depart_grammar_html(translator: Any, node: GrammarNode) -> None:
    translator.body.append("</pre>\n")


def _visit_grammar_literal(translator: Any, node: GrammarNode) -> None:
    translator.visit_literal_block(node)


def _depart_grammar_literal(translator: Any, node: GrammarNode) -> None:
    translator.depart_literal_block(node)


class MoonBitGrammar(SphinxDirective):
    """Render linked grammar productions from a MyST directive body."""

    has_content = True
    required_arguments = 0
    optional_arguments = 1
    final_argument_whitespace = False

    def run(self) -> list[nodes.Node]:
        group = self.arguments[0] if self.arguments else ""
        domain = self.env.domains.standard_domain
        grammar = GrammarNode(
            "\n".join(self.content),
            classes=[
                "moonbit-grammar",
                "notranslate",
                "literal-block",
            ],
        )
        grammar["translatable"] = False
        self.set_source_info(grammar)

        has_production = False
        for offset, line in enumerate(self.content):
            if not line.strip():
                if grammar.children:
                    grammar += nodes.Text("\n")
                continue

            match = _PRODUCTION_RE.match(line)
            if match:
                name, definition = match.groups()
                prefix = f"grammar-token-{group}" if group else "grammar-token"
                node_id = make_id(self.env, self.state.document, prefix, name)
                production_name = nodes.strong(
                    name, name, classes=["grammar-production"]
                )
                production_name["ids"].append(node_id)
                self.state.document.note_implicit_target(
                    production_name, production_name
                )
                object_name = f"{group}:{name}" if group else name
                domain.note_object(
                    "token", object_name, node_id, location=grammar
                )
                grammar += production_name
                grammar += nodes.Text(" ::= ")
                grammar.extend(self._parse_definition(definition, group))
                grammar += nodes.Text("\n")
                has_production = True
                continue

            match = _CONTINUATION_RE.match(line)
            if match and has_production:
                indentation, definition = match.groups()
                grammar += nodes.Text(indentation)
                grammar.extend(self._parse_definition(definition, group))
                grammar += nodes.Text("\n")
                continue

            line_number = self.content_offset + offset + 1
            raise self.error(
                "grammar lines must use 'name ::= definition' or an indented "
                "continuation "
                f"(line {line_number})"
            )

        if not has_production:
            raise self.error("moonbit-grammar requires at least one production")
        return [grammar]

    def _parse_definition(self, definition: str, group: str) -> list[nodes.Node]:
        result: list[nodes.Node] = []
        position = 0
        for match in _PART_RE.finditer(definition):
            self._append_meta(result, definition[position : match.start()])
            part = match.group(0)
            if part.startswith('"'):
                terminal = re.sub(r'\\(["\\])', r"\1", part[1:-1])
                result.append(
                    nodes.inline(
                        part, terminal, classes=["grammar-terminal"]
                    )
                )
            else:
                result.append(self._nonterminal(part[1:-1], group))
            position = match.end()

        self._append_meta(result, definition[position:])
        return result

    def _nonterminal(self, name: str, group: str) -> addnodes.pending_xref:
        target = name.lstrip("~")
        if ":" in target:
            display = target.split(":", 1)[1] if name.startswith("~") else target
        else:
            display = target
            target = f"{group}:{target}" if group else target

        reference = addnodes.pending_xref(
            "",
            refdomain="std",
            reftype="token",
            reftarget=target,
            refwarn=False,
        )
        reference += nodes.emphasis(
            name, display, classes=["grammar-nonterminal"]
        )
        return reference

    @staticmethod
    def _append_meta(result: list[nodes.Node], value: str) -> None:
        if value:
            result.append(
                nodes.inline(value, value, classes=["grammar-meta"])
            )


def setup(app: Sphinx) -> ExtensionMetadata:
    app.add_node(
        GrammarNode,
        html=(_visit_grammar_html, _depart_grammar_html),
        latex=(_visit_grammar_literal, _depart_grammar_literal),
        text=(_visit_grammar_literal, _depart_grammar_literal),
        man=(_visit_grammar_literal, _depart_grammar_literal),
        texinfo=(_visit_grammar_literal, _depart_grammar_literal),
        markdown=(_visit_grammar_literal, _depart_grammar_literal),
    )
    app.add_directive("moonbit-grammar", MoonBitGrammar)
    app.add_css_file("grammar.css")
    return {
        "version": "0.1.0",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
