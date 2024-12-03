# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'MoonBit Document'
copyright = '2024, International Digital Economy Academy'
author = 'International Digital Economy Academy'
release = 'v0.1.20241125'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

import sys
from pathlib import Path
sys.path.append(str(Path("_ext").resolve()))

extensions = ['myst_parser', 'lexer', 'sphinx_copybutton']

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', ".env", '.venv', "README", 'sources']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_book_theme'
html_static_path = ['_static']
html_theme_options = {
    "repository_url": "https://github.com/moonbitlang/moonbit-docs/",
    "path_to_docs": "next",
    "use_source_button": True,
    "use_edit_page_button": True,
    "use_issues_button": True,
}

# -- Options for LaTeX output ------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-latex-output
latex_engine = 'xelatex'
latex_elements = {
    'preamble': r"\usepackage{xeCJK}",
    'fvset': "\\fvset{formatcom={\\CJKsetecglue{}}}" # avoid having spaces around text in code blocks
}

# -- Options for myst_parser -------------------------------------------------
myst_heading_anchors = 3

# -- Options for gettext -----------------------------------------------------
gettext_additional_targets = ["literal-block"]